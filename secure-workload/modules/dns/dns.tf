resource "azurerm_private_dns_zone" "pe-dns-zone" {
 name = "privatelink.azurewebsites.net"
 resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pe-dns-zone-link"{
 name = "pe-dns-zone-link"
 resource_group_name = var.resource_group_name
 private_dns_zone_name = azurerm_private_dns_zone.pe-dns-zone.name
 virtual_network_id = var.vnet_id
}

