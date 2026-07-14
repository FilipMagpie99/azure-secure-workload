resource "azurerm_virtual_network" "vnet-secure-workload" {
  name                = "secure-workload-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "snet-app-gw" {
  name                 = "snet-app-gw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-secure-workload.name
  address_prefixes     = ["10.1.1.0/24"]
  service_endpoints = ["Microsoft.Web"]
}

resource "azurerm_subnet" "snet-app" {
  name                 = "snet-app"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-secure-workload.name
  address_prefixes     = ["10.1.2.0/28"]
  delegation {
    name = "delegation-app-service"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}


resource "azurerm_subnet" "snet-pe" {
  name                 = "snet-pe"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-secure-workload.name
  address_prefixes     = ["10.1.4.0/28"]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_network_security_group" "nsg-app" {
  name                = "nsg-app"
  location            = var.location
  resource_group_name = var.resource_group_name
}




resource "azurerm_subnet_network_security_group_association" "snet-app-nsg-association" {
  subnet_id                 = azurerm_subnet.snet-app.id
  network_security_group_id = azurerm_network_security_group.nsg-app.id
}



resource "azurerm_storage_account" "secure_workload_network_log_data" {
  name                      = "workloadnetworkfs2123"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  min_tls_version           = "TLS1_2"
}

resource "azurerm_network_watcher" "NetworkWatcher_secure_workload" {
  name                = "NetworkWatcher_secure_workload"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_watcher_flow_log" "azurerm_network_watcher_flow_log_secure_workload" {
  network_watcher_name = azurerm_network_watcher.NetworkWatcher_secure_workload.name
  resource_group_name  = var.resource_group_name
  name                 = "azurerm_network_watcher_flow_log_secure_workload"
  target_resource_id   = azurerm_virtual_network.vnet-secure-workload.id
  storage_account_id = azurerm_storage_account.secure_workload_network_log_data.id
  enabled            = true
  retention_policy {
    enabled = true
    days    = 90
  }

}