output "dns_zone_id" {
  value = azurerm_private_dns_zone.pe-dns-zone.id
}

output "dns_zone_id_db" {
  value = azurerm_private_dns_zone.pe-dns-zone-db.id
}