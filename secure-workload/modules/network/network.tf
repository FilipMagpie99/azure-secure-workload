resource "azurerm_virtual_network" "vnet-secure-workload" {
  name                = "secure-workload-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.1.0.0/16"]
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
  name                              = "snet-pe"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet-secure-workload.name
  address_prefixes                  = ["10.1.4.0/28"]
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
  #checkov:skip=CKV2_AZURE_41:sas_policy with 24h expiration configured (lines below); scanner false positive on module-nested resource, verified with checkov 3.3.9
  #checkov:skip=CKV_AZURE_206:Lab cost optimization; LRS sufficient for lab flow logs, production would use ZRS/GRS
  #checkov:skip=CKV_AZURE_33:Queue service not used on this account; blob-only flow log sink
  #checkov:skip=CKV2_AZURE_1:CMK encryption out of scope; platform-managed keys acceptable for lab log data
  name                     = "workloadnetworkfs223123"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = [split("/", var.dev_ip)[0]]
  }
  sas_policy {
    expiration_period = "01.00:00:00"
  }

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }
  allow_nested_items_to_be_public = false
}

resource "azurerm_network_watcher" "NetworkWatcher_secure_workload" {
  name                = "NetworkWatcherfs_secure_workload"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_watcher_flow_log" "azurerm_network_watcher_flow_log_secure_workload" {
  network_watcher_name = azurerm_network_watcher.NetworkWatcher_secure_workload.name
  resource_group_name  = var.resource_group_name
  name                 = "azurerm_network_watcher_flow_log_secure_workload"
  target_resource_id   = azurerm_virtual_network.vnet-secure-workload.id
  storage_account_id   = azurerm_storage_account.secure_workload_network_log_data.id
  enabled              = true
  retention_policy {
    enabled = true
    days    = 90
  }

}

resource "azurerm_network_security_group" "nsg-pe" {
  name                = "nsg-pe"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-VNet-PE-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["443", "5432"]
  }
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "pe" {
  subnet_id                 = azurerm_subnet.snet-pe.id
  network_security_group_id = azurerm_network_security_group.nsg-pe.id
}