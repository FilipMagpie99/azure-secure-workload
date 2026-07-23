resource "azurerm_service_plan" "secure-app_service_plan" {
  name                = "secure-app-service-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "B1" #switch to s1 for production testing
}

resource "azurerm_linux_web_app" "frontend_secure_workload" {
  name                                           = "fs99-frontend-secure-workload"
  location                                       = var.location
  resource_group_name                            = var.resource_group_name
  service_plan_id                                = azurerm_service_plan.secure-app_service_plan.id
  virtual_network_subnet_id                      = var.subnet_id_app
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  https_only                                     = true
  site_config {
    vnet_route_all_enabled        = true
    ftps_state                    = "Disabled"
    minimum_tls_version           = "1.2"
    scm_minimum_tls_version       = "1.2"
    http2_enabled                 = true
    ip_restriction_default_action = "Deny"

    ip_restriction {
      action                    = "Allow"
      name                      = "Allow-AppGW"
      virtual_network_subnet_id = var.subnet_id_appgw
    }

    scm_ip_restriction_default_action = "Deny"
    scm_use_main_ip_restriction       = false

    scm_ip_restriction {
      ip_address = var.dev_ip
      name       = "Allow-Dev-IP"
      action     = "Allow"
      priority   = 100
    }
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_linux_web_app" "backend_secure_workload" {
  name                                           = "fs99-backend-secure-workload"
  location                                       = var.location
  resource_group_name                            = var.resource_group_name
  service_plan_id                                = azurerm_service_plan.secure-app_service_plan.id
  virtual_network_subnet_id                      = var.subnet_id_app
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  public_network_access_enabled                  = true
  https_only                                     = true

  site_config {
    vnet_route_all_enabled            = true
    ftps_state                        = "Disabled"
    minimum_tls_version               = "1.2"
    scm_minimum_tls_version           = "1.2"
    http2_enabled                     = true
    ip_restriction_default_action     = "Deny"
    scm_ip_restriction_default_action = "Deny"
    scm_use_main_ip_restriction       = false

    scm_ip_restriction {
      ip_address = var.dev_ip
      name       = "Allow-Dev-IP"
      action     = "Allow"
      priority   = 100
    }
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "secure_workload_pe" {
  name                = "secure-workload-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.snet_pe_id
  private_service_connection {
    name                           = "secure-workload-psc-backend"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_linux_web_app.backend_secure_workload.id
    subresource_names              = ["sites"]
  }
  private_dns_zone_group {
    name                 = "secure-workload-dns-zone-group"
    private_dns_zone_ids = [var.dns_zone_id]
  }
}



