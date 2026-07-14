data "azuread_user" "current" {
  object_id = data.azurerm_client_config.current.object_id
}

data "azurerm_client_config" "current" {
}

resource "azurerm_postgresql_flexible_server" "secure_workload_postgres" {
  name                          = "fs99-secure-workload-postgres"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  version                       = "15"
  public_network_access_enabled = false
  zone                          = "3"

  authentication {
    password_auth_enabled         = false
    active_directory_auth_enabled = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }




  storage_mb = 32768

  sku_name = "B_Standard_B1ms"
}

resource "azurerm_postgresql_flexible_server_database" "secure_workload_postgres_db" {
  name      = "secure_workload_postgres_db"
  server_id = azurerm_postgresql_flexible_server.secure_workload_postgres.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}


resource "azurerm_postgresql_flexible_server_active_directory_administrator" "secure_workload_postgres_administrator" {
  server_name         = azurerm_postgresql_flexible_server.secure_workload_postgres.name
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azuread_user.current.object_id
  principal_name      = data.azuread_user.current.user_principal_name
  principal_type      = "User"
}



resource "azurerm_private_endpoint" "secure_workload_data_pe" {
  name                = "secure-workload-data-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.snet_pe_id

  private_service_connection {
    name                           = "secure-workload-data-psc-backend"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_postgresql_flexible_server.secure_workload_postgres.id
    subresource_names              = ["postgresqlServer"]
  }
  private_dns_zone_group {
    name                 = "secure-workload-dns-zone-group"
    private_dns_zone_ids = [var.dns_zone_id_db]
  }
}