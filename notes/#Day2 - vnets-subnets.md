# Day 2 — VNets - Subnets, IPs

````markdown
## Cheat sheet
```bash
az network vnet list -g azure-secure-workload-rg -o table #display all vnets in RG
az network vnet subnet list -g azure-secure-workload-rg --vnet-name app-vnet -o table #display all subnets in VNet
az network vnet create -g azure-secure-workload-rg --vnet-name hub-vnet --address-prefixes 10.0.0.0/16 -n AzureFirewallSubnet --address-prefixes 10.0.0.0/26 #Create VNet with one subnet
az network vnet subnet create -g azure-secure-workload-rg --vnet-name app-vnet --address-prefixes 10.1.0.0/16 -n app-frontend-nsg --address-prefixes 10.1.0.0/24 #Add subnet to the exisiting VNet
az network vnet peering create -g azure-secure-workload-rg -n AzureFirewallVnetToAppVnet --vnet-name hub-vnet --remote-vnet app-vnet --allow-vnet-access #create peering between hubvnet and appvnet
```
````
## Notes
- VNET can have multiple Subnets. At least 1 subnet must be defined at creation of Vnet.
- Subnets must be defined in CIDRs (/23,/24 etc.)
- By Default routing between subnets (within the same Vnet) is enabled.
- IP addresses can be assigned staticaly or dynamically to resources in the Vnet.
- Static IPs are the best for: -DNS resolution, IP baseds security models (allowing blocking certain IP), TLS/SSL linked to IP, Role-based VMs such as DCs or DNS servers.
- Public IP addresses usage should also be planned. Public IPs are assigned to NICs or LoadBalancers or VPN gateways and application gateways.

## 💡 Gotchas
- /24 in Azure Subnet gives only 251 IPs as .2 .3 are reserved for DNS in Azure. .1 is deault gateway, .0 identifies the Vnet and .255 is broadcast address.
- IP ranges cannot overlap in order for proper communication between subnets.
- Some services such as 'Azure Bastion' require dedicated subnet (/26). The same for Azure gateway (in scenario of connecting Vnet to onprem)
