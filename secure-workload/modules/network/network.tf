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

resource "azurerm_subnet" "snet-data" {
  name                 = "snet-data"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-secure-workload.name
  address_prefixes     = ["10.1.3.0/28"]
}

resource "azurerm_subnet" "snet-pe" {
  name                 = "snet-pe"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-secure-workload.name
  address_prefixes     = ["10.1.4.0/28"]
}

resource "azurerm_network_security_group" "nsg-app" {
  name                = "nsg-app"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_group" "nsg-data" {
  name                = "nsg-data"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_application_security_group" "asg-front" {
  name                = "asg-front"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_application_security_group" "asg-back" {
  name                = "asg-back"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "snet-app-nsg-association" {
  subnet_id                 = azurerm_subnet.snet-app.id
  network_security_group_id = azurerm_network_security_group.nsg-app.id
}

resource "azurerm_subnet_network_security_group_association" "snet-data-nsg-association" {
  subnet_id                 = azurerm_subnet.snet-data.id
  network_security_group_id = azurerm_network_security_group.nsg-data.id
}