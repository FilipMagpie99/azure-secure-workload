# Day 1 — Azure CLI: resource groups

## Cheat sheet
​```bash
az account show --output table #displays current sub
az group create -n azure-secure-workload-rg -l westeurope #creates a group
az group show -n azure-secure-workload-rg  #shows detail about group
az group list -o table #lists all groups in table format
az group delete -n azure-secure-workload-rg  #deletes group
az group update -n azure-secure-workload-rg --tags key=value
az group update -n azure-secure-workload-rg --set tags.key=value
​```

## Notes
Command anatomy: `az <group> <subgroup> <command> --<param> <value>`
...

## 💡 Gotchas
- RGs cost nothing — create/delete freely
- `az find` needs internet (aladdin service); use `--help` instead
- I can use --help after every part of the command to check for relevant example/command
- `//` is not a Bash comment — use `#`
- --set tags.key=value adds new tag to existing set, --tags key=value replaces the whole set of tags.