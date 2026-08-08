resource "azurerm_subnet" "snet-appgw" {
  name                 = "snet-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-secure-workload.name
  address_prefixes     = ["10.1.5.0/24"]
  service_endpoints    = ["Microsoft.Web"]
}

resource "azurerm_network_security_group" "nsg-appgw" {
  #checkov:skip=CKV_AZURE_160:Port 80 open solely for HTTP-to-HTTPS redirect enforced by CKV_AZURE_14
  #checkov:skip=CKV_AZURE_217:HTTP listener performs redirect-only; no traffic served over port 80
  name                = "nsg-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-HTTP-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["80", "443"]
  }
  security_rule {
    name                       = "Allow-GatewayManager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "GatewayManager"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "65200-65535"
  }
  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "*"
  }
}



resource "azurerm_subnet_network_security_group_association" "snet-appgw-nsg" {
  subnet_id                 = azurerm_subnet.snet-appgw.id
  network_security_group_id = azurerm_network_security_group.nsg-appgw.id
}

resource "azurerm_public_ip" "pub_ip_appgw" {
  name                = "pub_ip_appgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

}


# Create a Web Application Firewall (WAF) policy
resource "azurerm_web_application_firewall_policy" "secure_workload_waf_policy" {
  name                = "secure_workload_waf_policy"
  resource_group_name = var.resource_group_name
  location            = var.location

  # Configure the policy settings
  policy_settings {
    enabled                                   = true
    file_upload_limit_in_mb                   = 100
    js_challenge_cookie_expiration_in_minutes = 5
    max_request_body_size_in_kb               = 128
    mode                                      = "Detection"
    request_body_check                        = true
    request_body_inspect_limit_in_kb          = 128
  }

  # Define managed rules for the WAF policy
  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

}

# Create the Application Gateway
resource "azurerm_application_gateway" "secure_workload_appgw" {
  #checkov:skip=CKV_AZURE_160:Port 80 open solely for HTTP-to-HTTPS redirect enforced by CKV_AZURE_14
  #checkov:skip=CKV_AZURE_217:HTTP listener performs redirect-only; no traffic served over port 80
  name                = "secure-workload-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [var.appgw_identity_id]
  }

  ssl_certificate {
    name                = "appgw-kv-cert"
    key_vault_secret_id = var.appgw_cert_versionless_secret_id
  }
  # Configure the SKU and capacity
  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  # Enable autoscaling (optional)
  autoscale_configuration {
    min_capacity = 2
    max_capacity = 10
  }

  # Configure the gateway's IP settings
  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.snet-appgw.id
  }

  # Configure the frontend IP
  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.pub_ip_appgw.id
  }

  # Define the frontend port
  frontend_port {
    name = "appgw-frontend-port"
    port = 443
  }

  # Define the backend address pool with IP addresses
  backend_address_pool {
    name  = "appgw-backend-pool"
    fqdns = ["fsf99-frontend-secure-workload.azurewebsites.net"] # Replace with your backend FQDNs
  }

  # Configure backend HTTP settings
  backend_http_settings {
    name                                = "appgw-backend-http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 20
    pick_host_name_from_backend_address = true
  }

  frontend_port {
    name = "appgw-frontend-port-http"
    port = 80
  }

  http_listener {
    name                           = "appgw-http-listener-redirect"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "appgw-frontend-port-http"
    protocol                       = "Http"
  }

  redirect_configuration {
    name                 = "http-to-https-redirect"
    redirect_type        = "Permanent" # 301
    target_listener_name = "appgw-http-listener"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                        = "appgw-redirect-rule"
    priority                    = 10
    rule_type                   = "Basic"
    http_listener_name          = "appgw-http-listener-redirect"
    redirect_configuration_name = "http-to-https-redirect"
  }

  # Define the HTTP listener
  http_listener {
    name                           = "appgw-http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "appgw-frontend-port"
    protocol                       = "Https"
    ssl_certificate_name           = "appgw-kv-cert"
  }

  # Define the request routing rule
  request_routing_rule {
    name                       = "appgw-routing-rule"
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = "appgw-http-listener"
    backend_address_pool_name  = "appgw-backend-pool"
    backend_http_settings_name = "appgw-backend-http-settings"
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.secure_workload_waf_policy.id
}

