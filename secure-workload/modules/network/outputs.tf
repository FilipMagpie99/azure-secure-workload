output "subnet_id_app" {
  value = azurerm_subnet.snet-app.id
}
output "subnet_id_pe" {
  value = azurerm_subnet.snet-pe.id
}
output "vnet_id" {
  value = azurerm_virtual_network.vnet-secure-workload.id
}

output "subnet_id_appgw"{
  value = azurerm_subnet.snet-appgw.id
}

output "secure_workload_appgw_id" {
  value = azurerm_application_gateway.secure_workload_appgw.id
}