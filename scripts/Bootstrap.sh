#!/usr/bin/env bash
# Bootstrap layer for azure-secure-workload (see ADR 012).
# Creates everything that lives OUTSIDE Terraform state:
#   resource providers, state storage, pipeline identity (UMI + OIDC federation),
#   pipeline RBAC, deployer grants, GitHub repo variables and secrets.
# Idempotent: safe to re-run; existing resources are left as they are.
# Run after a tenant reset, before the first terraform apply.

set -euo pipefail

# ---------------------------------------------------------------- parameters
LOCATION="swedencentral"
RG_WORKLOAD="rg-secure-workload"
RG_STATE="rg-tfstate-secureworkload"
STATE_CONTAINER="tfstate"
UMI_NAME="umi-github-cicd"
REPO="FilipMagpie99/azure-secure-workload"
# Built-in role definition GUID: Key Vault Secrets User (stable across tenants)
KV_SECRETS_USER_GUID="4633458b-17de-408a-b874-0445c86b69e6"
# Pass an existing state account name as $1 to reuse it; otherwise a new one is created.
STATE_ACC="${1:-}"

step() { printf '\n==> %s\n' "$*"; }

# ---------------------------------------------------------------- session
step "Azure session"
az account show -o none || { echo "Run 'az login' first."; exit 1; }
SUB=$(az account show --query id -o tsv)
TENANT=$(az account show --query tenantId -o tsv)
MY_OID=$(az ad signed-in-user show --query id -o tsv)
MY_UPN=$(az ad signed-in-user show --query userPrincipalName -o tsv)
echo "subscription: $SUB"
echo "tenant:       $TENANT"
echo "user:         $MY_UPN ($MY_OID)"

# ---------------------------------------------------------------- providers
step "Resource providers (fresh subscriptions ship unregistered)"
for RP in Microsoft.Storage Microsoft.Network Microsoft.Web Microsoft.KeyVault \
          Microsoft.DBforPostgreSQL Microsoft.ManagedIdentity \
          Microsoft.OperationalInsights Microsoft.Insights; do
  STATE=$(az provider show -n "$RP" --query registrationState -o tsv 2>/dev/null || echo NotRegistered)
  if [ "$STATE" != "Registered" ]; then
    echo "registering $RP"
    az provider register --namespace "$RP" -o none
  fi
done
echo "waiting for Microsoft.Storage (needed immediately for state account)"
az provider register --namespace Microsoft.Storage --wait -o none

# ---------------------------------------------------------------- resource groups
step "Resource groups"
az group create -n "$RG_WORKLOAD" -l "$LOCATION" -o none
az group create -n "$RG_STATE"    -l "$LOCATION" -o none

# ---------------------------------------------------------------- state storage
step "Remote state storage"
if [ -z "$STATE_ACC" ]; then
  STATE_ACC="sttfstatesecwl$RANDOM$RANDOM"
fi
if ! az storage account show -n "$STATE_ACC" -g "$RG_STATE" -o none 2>/dev/null; then
  az storage account create -n "$STATE_ACC" -g "$RG_STATE" -l "$LOCATION" \
    --sku Standard_LRS --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-shared-key-access false \
    --allow-blob-public-access false -o none
fi
STATE_SCOPE=$(az storage account show -n "$STATE_ACC" -g "$RG_STATE" --query id -o tsv)

az role assignment create --assignee-object-id "$MY_OID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" --scope "$STATE_SCOPE" -o none 2>/dev/null || true

echo "waiting 120s for data plane RBAC propagation before container create"
sleep 120
az storage container create -n "$STATE_CONTAINER" --account-name "$STATE_ACC" --auth-mode login -o none

# ---------------------------------------------------------------- pipeline identity
step "Pipeline identity (UMI + federated credentials)"
az identity create -g "$RG_WORKLOAD" -n "$UMI_NAME" -l "$LOCATION" -o none
CLIENT_ID=$(az identity show -g "$RG_WORKLOAD" -n "$UMI_NAME" --query clientId -o tsv)
PRINCIPAL=$(az identity show -g "$RG_WORKLOAD" -n "$UMI_NAME" --query principalId -o tsv)
echo "clientId:    $CLIENT_ID"
echo "principalId: $PRINCIPAL"

fed() { # name subject
  az identity federated-credential create \
    --identity-name "$UMI_NAME" -g "$RG_WORKLOAD" \
    --name "$1" \
    --issuer https://token.actions.githubusercontent.com \
    --subject "$2" \
    --audiences api://AzureADTokenExchange -o none 2>/dev/null || echo "credential $1 already present"
}
fed gh-main "repo:$REPO:ref:refs/heads/main"
fed gh-pr   "repo:$REPO:pull_request"

echo "waiting 60s for service principal propagation before role assignments"
sleep 60

# ---------------------------------------------------------------- pipeline RBAC (ADR 013)
step "Pipeline RBAC"
RGID=$(az group show -n "$RG_WORKLOAD" --query id -o tsv)

az role assignment create --assignee-object-id "$PRINCIPAL" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" --scope "/subscriptions/$SUB" -o none 2>/dev/null || true

az role assignment create --assignee-object-id "$PRINCIPAL" \
  --assignee-principal-type ServicePrincipal \
  --role "Role Based Access Control Administrator" \
  --scope "/subscriptions/$SUB" \
  --condition-version "2.0" \
  --condition "((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {$KV_SECRETS_USER_GUID}))" \
  -o none 2>/dev/null || true

az role assignment create --assignee-object-id "$PRINCIPAL" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" --scope "$STATE_SCOPE" -o none 2>/dev/null || true

# Deployer grants (ADR 014): both deployers hold Certificates Officer on the workload RG
az role assignment create --assignee-object-id "$PRINCIPAL" \
  --assignee-principal-type ServicePrincipal \
  --role "Key Vault Certificates Officer" --scope "$RGID" -o none 2>/dev/null || true
az role assignment create --assignee-object-id "$MY_OID" \
  --assignee-principal-type User \
  --role "Key Vault Certificates Officer" --scope "$RGID" -o none 2>/dev/null || true

# ---------------------------------------------------------------- github config
step "GitHub repository variables and secrets"
gh variable set ARM_CLIENT_ID       --repo "$REPO" --body "$CLIENT_ID"
gh variable set ARM_TENANT_ID       --repo "$REPO" --body "$TENANT"
gh variable set ARM_SUBSCRIPTION_ID --repo "$REPO" --body "$SUB"
DEV_IP="$(curl -s ifconfig.me)/32"
gh secret set TF_VAR_dev_ip --repo "$REPO" --body "$DEV_IP"
echo "dev_ip secret set to $DEV_IP (single source, see gotcha: tfvars drift)"

# ---------------------------------------------------------------- summary
step "Bootstrap complete. Manual follow-ups:"
cat <<EOF
1. backend "azurerm" block: storage_account_name = "$STATE_ACC"
2. terraform init -reconfigure
3. PostgreSQL Entra admin variables (modules/compute):
     pg_entra_admin_object_id = "$MY_OID"
     pg_entra_admin_upn       = "$MY_UPN"
4. Local tfvars: dev_ip = "$DEV_IP"
5. Role assignments need ~2 min propagation before the first apply.
EOF
