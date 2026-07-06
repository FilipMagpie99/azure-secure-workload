provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {
}


resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "network" {
  source              = "./modules/network"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

module "compute" {
  source              = "./modules/compute"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id_app       = module.network.subnet_id_app
  dns_zone_id         = module.dns.dns_zone_id
  snet_pe_id         = module.network.subnet_id_pe
}


module "dns"{
  source = "./modules/dns"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  vnet_id             = module.network.vnet_id
}

module "visibility" {
  source              = "./modules/visibility"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subscription_id      = data.azurerm_subscription.current.subscription_id
  app_service_ids = {
    frontend = module.compute.frontend_app_service_id
    backend  = module.compute.backend_app_service_id
  }
}