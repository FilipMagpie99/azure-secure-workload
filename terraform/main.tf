terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"          
    }
  }
}

provider "azurerm" {
  features {}                     
}

resource "azurerm_resource_group" "lab" {
  name     = "rg-terraform-lab"
  location = "westeurope"
  tags = {
    project = "portfolio"
    env     = "lab"
  }
}