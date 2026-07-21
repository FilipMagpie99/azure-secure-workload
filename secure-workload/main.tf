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

module "governance" {
  source            = "./modules/governance"
  resource_group_id = azurerm_resource_group.rg.id
}
module "security" {
  source              = "./modules/security"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
module "network" {
  source                           = "./modules/network"
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  appgw_identity_id                = module.security.appgw_identity_id
  appgw_cert_versionless_secret_id = module.security.appgw_cert_versionless_secret_id
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
  kv_id                    = module.security.kv_id
  app_service_ids = {
    frontend = module.compute.frontend_app_service_id
    backend  = module.compute.backend_app_service_id
  }

}

moved {
  from = module.compute.azurerm_key_vault_certificate.appgw_cert
  to   = module.security.azurerm_key_vault_certificate.appgw_cert
}
moved {
  from = module.compute.azurerm_key_vault.kv_secure_workload
  to   = module.security.azurerm_key_vault.kv_secure_workload
}
moved {
  from = module.compute.azurerm_role_assignment.deployer_kv_certificates_officer
  to   = module.security.azurerm_role_assignment.deployer_kv_certificates_officer
}
moved {
  from = module.compute.azurerm_role_assignment.appgw_identity_keyvault_reader
  to   = module.security.azurerm_role_assignment.appgw_identity_keyvault_reader
}
moved {
  from = module.compute.azurerm_user_assigned_identity.appgw_identity
  to   = module.security.azurerm_user_assigned_identity.appgw_identity
}

