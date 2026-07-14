provider "azurerm" {
  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_subscription" "current" {
}


resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

module "network" {
  source                           = "./modules/network"
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  appgw_identity_id                = module.compute.appgw_identity_id
  appgw_cert_versionless_secret_id = module.compute.appgw_cert_versionless_secret_id
}

module "compute" {
  source              = "./modules/compute"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id_app       = module.network.subnet_id_app
  dns_zone_id         = module.dns.dns_zone_id
  snet_pe_id          = module.network.subnet_id_pe
  dns_zone_id_db      = module.dns.dns_zone_id_db
  subnet_id_appgw     = module.network.subnet_id_appgw
  dev_ip              = var.dev_ip
}


module "dns" {
  source              = "./modules/dns"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  vnet_id             = module.network.vnet_id
}

module "visibility" {
  source                   = "./modules/visibility"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  subscription_id          = data.azurerm_subscription.current.subscription_id
  postgres_server_id       = module.compute.postgres_server_id
  secure_workload_appgw_id = module.network.secure_workload_appgw_id
  kv_id = module.compute.kv_id
  app_service_ids = {
    frontend = module.compute.frontend_app_service_id
    backend  = module.compute.backend_app_service_id
  }

}