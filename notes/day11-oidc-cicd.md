# Day 11 — GitHub Actions CI/CD with OIDC workload identity federation

## Cheat sheet

```bash
# --- OIDC bootstrap (identity side, runs outside Terraform) ---
az identity create -g rg-secure-workload -n umi-github-cicd -l swedencentral
az identity show -g rg-secure-workload -n umi-github-cicd \
  --query "{clientId:clientId, principalId:principalId}" -o table

az identity federated-credential create \
  --identity-name umi-github-cicd -g rg-secure-workload \
  --name gh-main \
  --issuer https://token.actions.githubusercontent.com \
  --subject "repo:FilipMagpie99/azure-secure-workload:ref:refs/heads/main" \
  --audiences api://AzureADTokenExchange
# second credential: --name gh-pr --subject "repo:FilipMagpie99/azure-secure-workload:pull_request"

az identity federated-credential list --identity-name umi-github-cicd -g rg-secure-workload -o table

# --- pipeline RBAC (4 grants) ---
# Contributor              -> /subscriptions/$SUB          (stack creates the RG)
# RBAC Administrator       -> /subscriptions/$SUB          (with condition, whitelist of grantable roles)
# Storage Blob Data Contr. -> state storage account        (data plane, AAD auth backend)
# KV Certificates Officer  -> workload RG                  (deployer holds it, stack does not grant it)

# --- repo config ---
gh variable set ARM_CLIENT_ID --body "<umi clientId>"
gh variable set ARM_TENANT_ID --body "<tenantId>"
gh variable set ARM_SUBSCRIPTION_ID --body "<subId>"
gh secret set TF_VAR_dev_ip --body "$(curl -s ifconfig.me)/32"   # secret, not variable: repo goes public

# --- daily PR flow ---
git checkout main && git pull
git checkout -b dayN/topic
# ...work, checkpoint commits...
git push -u origin dayN/topic
gh pr create --title "..." --body "..."
gh pr checks --watch
gh pr merge --squash --delete-branch
git checkout main && git pull

# --- pipeline ops ---
gh run list --workflow=apply.yml -L 3        # find run ID
gh run rerun <ID> --failed                   # rerun failed jobs, same commit, fresh secrets
gh run watch <ID>

# --- checkov local ---
checkov -d . --check CKV_AZURE_218           # single check, resolves scanner vs docs disputes
```

## Notes

**Token model.** GitHub Actions is not a separate service, it activates on the presence of YAML files under `.github/workflows/`. With `permissions: id-token: write` the runner gets two env vars (`ACTIONS_ID_TOKEN_REQUEST_URL`, `ACTIONS_ID_TOKEN_REQUEST_TOKEN`) and can request a short-lived JWT signed by GitHub. The token carries claims describing the execution context: `iss` (GitHub), `aud` (set by the requester, `api://AzureADTokenExchange` for Entra), `sub` (repo + trigger context).

**Two subjects, one identity.** The `sub` claim depends on the trigger:
- `push` to main: `repo:FilipMagpie99/azure-secure-workload:ref:refs/heads/main`
- `pull_request`: `repo:FilipMagpie99/azure-secure-workload:pull_request` (no branch name: every PR gets the same subject, which is correct because PRs are only trusted to plan)

Trust narrows as privileges grow: only code that passed the merge gate presents the main subject, and only that path runs apply.

**Exchange.** Entra verifies the JWT signature against GitHub's JWKS, then string-matches `iss`/`sub`/`aud` against the federated credential. Terraform (azurerm provider and backend) performs this exchange natively when `ARM_USE_OIDC=true`, no `azure/login` step needed. Provider and backend authenticate independently: `use_oidc = true` must be set in both.

**Plan/apply pattern.** `terraform plan -out=tfplan` + `terraform apply tfplan` executes exactly the reviewed plan instead of recomputing. `concurrency` with `cancel-in-progress: false` queues applies instead of racing for the blob lease.

**Checkov triage** (36 findings): fix quick wins aligned with the project thesis (App Service logs, health checks, App GW SSL policy, NSG on snet-pe, blob soft delete), document accepted risk as inline `#checkov:skip=<ID>:<rationale>` annotations, keep a named backlog for the rest (KV and log-storage network hardening). Result: 58 passed, 20 skipped with rationale, 6 open backlog items. `--soft-fail` stays until the backlog closes, then the gate goes hard.

**Decode vs verify.** Dumping a JWT payload (`cut -d '.' -f2 | base64 -d`) is inspection, not verification. Signature verification against JWKS is Entra's job during the exchange. Interview-grade distinction.

## 💡 Gotchas

- Workflows live in `.github/workflows/`, not `workflows/`. Wrong path fails silently: GitHub never sees the file.
- `permissions:` block is exclusive: declaring anything zeroes all other permissions to `none`. Missing `id-token: write` means the token endpoint env vars do not exist at all.
- Federated credential `subject` is an exact string match. Take it from a real token dump, not from docs.
- `terraform init`: backend location changed = `-migrate-state`, connection parameters changed (same state, new auth) = `-reconfigure`. Wrong choice in the reverse direction leaves state behind.
- Fresh subscription: `SubscriptionNotFound` from a resource provider endpoint is `MissingSubscriptionRegistration` in disguise. Third variant: `NoRegisteredProviderFound`. All three = `az provider register`.
- Global DNS namespaces collide across tenants with your own dead resources (PostgreSQL FQDN, KV name, App Service, storage). `random_string` suffix in Terraform survives applies, changes only with fresh state.
- Same value in two places drifts: tfvars vs GitHub secret (`dev_ip`), old hostname in App GW config, dead `$PRINCIPAL` after tenant reset. Single source + script beats memory.
- `scm_ip_restriction.ip_address` requires CIDR notation (`x.x.x.x/32`). ARM says "invalid CIDR", not "access denied": syntax error, not a stale address.
- Scanner check implementations accept a narrower value list than Azure does. `AppGwSslPolicy20220101` is valid per docs but only the `...S` variant passes CKV_AZURE_218. Resolve with a local single-check run, not with docs.
- CKV2 (graph) checks can false-positive on module-nested resources: CKV2_AZURE_41 failed with a correct `sas_policy` present, verified on checkov 3.3.9. Skip with scanner version in the rationale.
- `gh pr merge` runs `git checkout main` afterwards and aborts on a dirty working tree (merge itself succeeds). `git status` before merging, or `git stash` -> checkout -> `stash pop` onto a new branch.
- A PR tracks its branch: pushing to the same branch updates the open PR and reruns checks. New branch + new PR only after the previous one merged.
- `python3 pip install` tries to open a file named `pip`. It is `python3 -m pip` (or `brew install checkov`).
- zsh does not treat `#` as a comment interactively by default: `setopt interactivecomments` in `~/.zshrc`.
- App GW updates take tens of minutes and caches certificates: "works after a config change" proves nothing until you force a refresh (stop/start).
