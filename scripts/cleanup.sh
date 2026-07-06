#!/usr/bin/env bash
set -euo pipefail

# ================== KONFIGURACJA — ZWERYFIKOWANA GREPEM versions.tf ==================
KEEP_STATE_RG="rg-tfstate-secureworkload"   # ŻYWY backend: sttfstatesecwl28845 / prod.tfstate
DROP_RGS=(
  "learning-rg"
  "azure-secure-workload-rg"                # stary lab z rozbiegu, NIE aktualny projekt
  "rg-never-gonna-let-you-down"
  "rg-never-gonna-run-around"
  "rg-and-desert-you"
  "rg-tfstate"                              # martwy state (polandcentral / sttfstatefilip7123)
)
# =====================================================================================

echo "== Subskrypcja, na której działam: =="
az account show --query "{name:name, id:id}" -o table
echo
echo "== ZOSTAJE: ${KEEP_STATE_RG} + NetworkWatcherRG =="
echo "== DO SKASOWANIA: =="
printf ' - %s\n' "${DROP_RGS[@]}"
echo
echo "!! Przed 'tak' upewnij się, że w sttfstatefilip7123 nie ma żywego state:"
echo "   az storage blob list --account-name sttfstatefilip7123 --container-name tfstate --auth-mode login -o table"
read -rp "Kontynuować? [tak/NIE] " ans
[[ "$ans" == "tak" ]] || { echo "Przerwano."; exit 1; }

# --- Recovery Services Vault (rsv-learning) blokuje kasowanie RG — rozbrojenie ---
az backup vault backup-properties set \
  --name rsv-learning -g learning-rg --soft-delete-feature-state Disable 2>/dev/null || true
for c in $(az backup item list -g learning-rg -v rsv-learning \
             --query "[].{c:containerName,n:name}" -o tsv 2>/dev/null | awk '{print $1";"$2}'); do
  az backup protection disable -g learning-rg -v rsv-learning \
    --container-name "${c%%;*}" --item-name "${c##*;}" \
    --backup-management-type AzureIaasVM --delete-backup-data true --yes || true
done

# --- Kasowanie RG równolegle ---
for rg in "${DROP_RGS[@]}"; do
  echo ">> delete: $rg"
  az group delete --name "$rg" --yes --no-wait
done

echo ">> Czekam na zakończenie kasowań (może potrwać kilkanaście minut)..."
for rg in "${DROP_RGS[@]}"; do
  az group wait --name "$rg" --deleted --timeout 1800 2>/dev/null || true
done

# --- Purge soft-deleted Key Vaults (rezerwują nazwy: kv-lab-fs01, learning-key0vault01) ---
for kv in $(az keyvault list-deleted --query "[].name" -o tsv); do
  echo ">> purge KV: $kv"
  az keyvault purge --name "$kv"
done

# --- Purge soft-deleted Cognitive Services (ai-services-lr, sroczynskif99-*) ---
az cognitiveservices account list-deleted \
  --query "[].{n:name,l:location,rg:resourceGroup}" -o tsv | while IFS=$'\t' read -r n l rg; do
  echo ">> purge CogSvc: $n"
  az cognitiveservices account purge --name "$n" --location "$l" --resource-group "$rg"
done

# --- Osierocone role assignments (po skasowanych tożsamościach) ---
az role assignment list --all \
  --query "[?principalName==''].id" -o tsv | while read -r raid; do
  echo ">> delete role assignment: $raid"
  az role assignment delete --ids "$raid"
done

# --- Tag na żywym state-RG, żeby następne sprzątanie nie było archeologią ---
az group update -n "${KEEP_STATE_RG}" --tags purpose=tfstate-live project=azure-secure-workload

# --- Weryfikacja końcowa ---
echo "== POZOSTAŁO: =="
az group list -o table
echo
az resource list -o table