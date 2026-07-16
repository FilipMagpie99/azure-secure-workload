terraform {
  required_version = ">= 1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-secureworkload"
    storage_account_name = "sttfstatesecwl7c1558"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
    use_azuread_auth     = true
  }
}