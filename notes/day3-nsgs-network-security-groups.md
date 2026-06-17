# Day 3 — NSGs Network Security Groups

## Cheat sheet
```bash
# az ...
az network asg create -g azure-secure-workload-rg -n app-asg #creating ApplicationSecurityGroup
az network nic create -g azure-secure-workload-rg --vnet-name app-vnet --subnet app-frontend-asg -n VM1Nic #creating NIC in given subnet
az network public-ip create -g azure-secure-workload-rg -n VM1-PublicIP --sku Standard #creating public IP
az network nic ip-config create -g azure-secure-workload-rg --nic-name VM1Nic -n ipconfig1 --public-ip-address VM1-PublicIP #Updating NIC ip config to add public IP
az vm create -g azure-secure-workload-rg -n VM1 --nics VM1Nic --image Ubuntu2204 --size Standard_B2ts_v2 --admin-username filipadmin --generate-ssh-keys #Creating VM and assigning NIC to it
az network nic create -g azure-secure-workload-rg --vnet-name app-vnet --subnet app-vnet-nsg -n VM2Nic #second NIC
az vm create -g azure-secure-workload-rg -n VM2 --nics VM2Nic --image Ubuntu2204 --size Standard_B2ts_v2 --admin-username filipadmin --generate-ssh-keys #Creating second VM and assigning second NIC to it
az network nsg create -g azure-secure-workload-rg  -n app-nsg-config #Creating nsg 
az network nsg rule create -g azure-secure-workload-rg --nsg-name app-nsg-config -n AllowSSH --priority 100 --source-address-prefixes '*' --destination-port-ranges 22 --destination-asgs app-asg --access Allow --protocol tcp --description "AllowSSH"
```

## Notes
- Created ASG (Application security group). It works as given category of machine which then can be used to reference it in the rules after assigning it to NIC.
- I've created NIC (network interface card) and then assigned it to VM when creating. NIC places VM in the given subnet.
- Create NSG, created NSG rule.

## 💡 Gotchas
- NSG rule doesn't accept "Any" as valid source/destination you must use "*"
- To apply ASG to NSG, use --destination-asgs/--source-asgs
