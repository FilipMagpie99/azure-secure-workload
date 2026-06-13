# Day 1 — Azure CLI: resource groups

## Cheat sheet
````markdown
## Cheat sheet
```bash
az account show -o table                                  # current subscription
az group create -n azure-secure-workload-rg -l westeurope # create
az group show -n azure-secure-workload-rg                 # show details
az group list -o table                                    # list all (table)
az group delete -n azure-secure-workload-rg               # delete
az group update -n azure-secure-workload-rg --tags k=v    # REPLACE all tags
az group update -n azure-secure-workload-rg --set tags.k=v # ADD/merge one tag
```
````

## Notes
Command anatomy: `az <group> <subgroup> <command> --<param> <value>`
...

## 💡 Gotchas
- RGs cost nothing — create/delete freely
- `az find` needs internet (aladdin service); use `--help` instead
- I can use --help after every part of the command to check for relevant example/command
- `//` is not a Bash comment — use `#`
- --set tags.key=value adds new tag to existing set, --tags key=value replaces the whole set of tags.