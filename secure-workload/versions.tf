terraform {
  required_version = ">= 1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-secureworkload"
    storage_account_name = "sttfstatesecwl1511418689"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
    use_azuread_auth     = true
    use_oidc             = true
  }
}