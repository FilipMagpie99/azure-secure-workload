moved {
  from = azurerm_application_security_group.af-asg
  to   = module.network.azurerm_application_security_group.af-asg
}

moved {
  from = azurerm_network_interface.vm1-nic
  to   = module.network.azurerm_network_interface.vm1-nic
}

moved {
  from = azurerm_network_interface_application_security_group_association.asgtonic
  to   = module.network.azurerm_network_interface_application_security_group_association.asgtonic
}

moved {
  from = azurerm_network_security_group.af-nsg
  to   = module.network.azurerm_network_security_group.af-nsg
}


moved {
  from = azurerm_subnet.AzureFirewallSubnet
  to   = module.network.azurerm_subnet.AzureFirewallSubnet
}

moved {
  from = azurerm_subnet.backend
  to   = module.network.azurerm_subnet.backend
}

moved {
  from = azurerm_subnet.frontend
  to   = module.network.azurerm_subnet.frontend
}

moved {
  from = azurerm_subnet_network_security_group_association.nsgbackend
  to   = module.network.azurerm_subnet_network_security_group_association.nsgbackend
}

moved {
  from = azurerm_virtual_network.app_vnet
  to   = module.network.azurerm_virtual_network.app_vnet
}

