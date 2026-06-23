resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
resource "azurerm_network_security_group" "af-nsg"{
    name = "app-frontend-nsg"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_application_security_group" "af-asg"{
    name = "app-frontend-asg"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    }
resource "azurerm_virtual_network" "app_vnet"{
    name               = "app-vnet"
    location           = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space   = var.vnet_address_space
}
resource "azurerm_subnet" "frontend"{
    name = "frontend"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.app_vnet.name
    address_prefixes = ["10.1.0.0/24"]
}
resource "azurerm_subnet" "backend"{
    name ="backend"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.app_vnet.name
    address_prefixes = ["10.1.1.0/24"]
}
resource "azurerm_subnet" "AzureFirewallSubnet"{
    name = "AzureFirewallSubnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.app_vnet.name
    address_prefixes = ["10.1.63.0/26"]
}
resource "azurerm_network_interface" "vm1-nic"{
    name = "vm1-nic"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    
    ip_configuration{
        name ="internal"
        subnet_id = azurerm_subnet.frontend.id
        private_ip_address_allocation = "Dynamic"
    }

}

resource "azurerm_subnet_network_security_group_association" "nsgbackend"{
  subnet_id = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.af-nsg.id
}
resource "azurerm_network_interface_application_security_group_association" "asgtonic" {
    network_interface_id = azurerm_network_interface.vm1-nic.id
    application_security_group_id = azurerm_application_security_group.af-asg.id
}