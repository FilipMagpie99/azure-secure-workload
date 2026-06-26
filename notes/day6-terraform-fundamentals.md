# Day 6 — Terraform fundamentals

## Cheat sheet
```bash
terraform fmt #formats all files within the working directory (syntax)
terraform init #initializes the providers (downloads plugins and modules), once in a project or after a change of providers. It initializes the working directory
```

## Notes
- Write -> Init -> Plan -> Apply -> Destroy
- Init - downloading providers (AWS,Azure,GCP), downloading modules. Gathering all the dependencies in working directory. Configures where state file will be stored and creates lock file.
- Lock file - locks dependency versions for consistency accross env.
name: .terraform.lock.hcl it's stored in working directory.


- Terraform uses language called HCL (HashiCorp Configuration Language). HCL files use the .tf .tfvars file extensions.

## 💡 Gotchas
- 
