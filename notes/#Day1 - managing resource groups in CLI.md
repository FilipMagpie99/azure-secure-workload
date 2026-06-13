# Day 1 — Azure CLI: resource groups

## Cheat sheet
​```bash
az group create -n azure-secure-workload-rg -l westeurope #creates a group
az group show -n <name> #shows detail about group
az group list -o table #lists all groups in table format
az group delete -n <name> #deletes group
az group updat -n azure-secure-workload-rg --set tags.Owner='{"Owner":"FS"}'
​```

## Notes
Command anatomy: `az <group> <subgroup> <command> --<param> <value>`
...

## 💡 Gotchas
- RGs cost nothing — create/delete freely
- `az find` needs internet (aladdin service); use `--help` instead
- `//` is not a Bash comment — use `#`