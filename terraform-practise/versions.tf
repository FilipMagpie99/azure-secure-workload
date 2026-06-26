terraform {
  required_version = ">= 1.12.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatefilip7123"
    container_name       = "tfstate"
    key                  = "practise.terraform.tfstate"
    use_azuread_auth     = true
  }
}