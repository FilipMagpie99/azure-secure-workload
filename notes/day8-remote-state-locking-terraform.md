# Day 8 — Remote state + locking - Terraform

## Cheat sheet
```bash
terraform init #initalizes terraform state - can be used with new project 
terraform init -migrate-state #migrates exisiting local state to the new backend (remote)
terraform state list #shows all resource names tracked by terraform
terraform state show #shows every resource
terraform state show <resourcename> #shows details about a specific resource
terraform plan -refresh-only #shows changes in the cloud vs in terraform state
terraform apply #overwrites any changes with terraform state
terraform apply -refresh-only #accepts the changes and puts them to terraform

```

## Notes
- Chicken-and-egg problem - storage account, which holds state needs to be defined before terraform can use it to store remote state.
- Terraform uses state to determine which changes needs to be applied to your infrastructure after terraform apply.
- Purpose of the state is to store binding between objects in a remote system and resource instances declared in your configuration.
- By Default stored in terraform.tfstate and back in terraform.tfstate.backup
- State can be stored locally (local - by default) or remotely (many providers azurerm in my case [storage account container])
- State *DRIFT* means that state is not matching the real world infrastructure. running terraform plan - will show us that there is a drift. We can either accept the change "terraform apply -refresh-only" (it makes changes inside of our state file) or override the change with "terraform apply".
- When Terraform loses state file, it creates a new state file and applies this new configuration as new resources to the cloud. terraform plan will create a new state file.

## 💡 Gotchas
- Avoid storing remote state in solutions that don't support state locking and secure access control, because od the risk of data loss or exposure of secrets.
- Terraform expects 1-1 relation between  configured resources and remote object.
- Terraform always does a refresh of state before applying and changes to infrastructure
- State file includes metadata, which helps to manage the dependencies between resources 
- Terraform needs to "lock" the state file when performing any operations that might write to the file (to avoid conflict)
- Any changes to "backend" requires terraform init (to reinitialize the configuration)