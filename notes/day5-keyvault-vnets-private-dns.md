# Day 5 — KeyVault + Vnets private DNS

## Cheat sheet
```bash
az keyvault create -g azure-secure-workload-rg -n kv-lab-fs01 --enable-rbac-authorization true --enable-purge-protection true #creating keyvault
APP_MI=$(az webapp identity show -g azure-secure-workload-rg -n app-lab-fs01 --query principalId -o tsv) #creates a variable APP_MI, which holds the prinicpalId of managed identity assigned to app-lab-fs01
KV_ID=$(az keyvault show -g azure-secure-workload -n kv-lab-fs01 --query id -o tsv) #creates a varuabke KV_ID, which hold ID of keyvault resource
az role assignment create --assignee-object-id $APP_MI --assignee-principal-type ServicePrincipal -role "Key Vault Secrets User" --scope $KV_ID #creates role assignment (RBAC) for MI of app to KeyVault

# 3. Private endpoint for the vault sub-resource
az network private-endpoint create -g azure-secure-workload-rg -n pe-kv \
  --vnet-name vnet-secure-workload --subnet snet-pe \
  --private-connection-resource-id "$KV_ID" --group-id vault --connection-name conn-kv

# 4. Private DNS zone + link to VNet + zone group  ← the crux
az network private-dns zone create -g azure-secure-workload-rg -n privatelink.vaultcore.azure.net
az network private-dns link vnet create -g azure-secure-workload-rg \
  --zone-name privatelink.vaultcore.azure.net --name link-vnet \
  --virtual-network vnet-secure-workload --registration-enabled false
az network private-endpoint dns-zone-group create -g azure-secure-workload-rg \
  --endpoint-name pe-kv --name kv-zone-group \
  --private-dns-zone privatelink.vaultcore.azure.net --zone-name vault

# 5. NOW lock the front door — disable public access
az keyvault update -g azure-secure-workload-rg -n kv-lab-fs01 --public-network-access Disabled
```

## Notes
- Authentication and authorization are both important when setting up secure access to resource in Azure
- Private DNS zone allows for VNET DNS requests being resolved to private IP addresses instead of public
- Private DNS zone is required to disable public IP and keep connectivity
- Create private endpoint -> Create private DNS zone -> Link DNS zone to VNET -> Link DNS zone to private endpoint -> Disable public IP
## 💡 Gotchas
- privatelink.vaultcore.azure.net is not a random name, it's mapped to keyvault, the same for sql etc.
