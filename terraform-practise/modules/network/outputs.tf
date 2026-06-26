output "vnet_id" {
  value = azurerm_virtual_network.app_vnet.id
}

output "frontend_subnet_id" {
  value = azurerm_subnet.frontend.id
}

output "nsg_id" {
  value = azurerm_network_security_group.af-nsg.id
}