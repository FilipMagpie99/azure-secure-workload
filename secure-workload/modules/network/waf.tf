resource "azurerm_subnet" "snet-appgw" {
  name                 = "snet-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet-secure-workload.name
  address_prefixes     = ["10.1.5.0/24"]
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
    enabled                                   = false
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

  # Define a custom rule to block traffic from a specific IP address
#   custom_rules {
#     name      = "BlockSpecificIP"
#     priority  = 1
#     rule_type = "MatchRule"

#     match_conditions {
#       match_variables {
#         variable_name = "RemoteAddr"
#       }
#       operator           = "IPMatch"
#       negation_condition = false
#       match_values       = ["192.168.1.1"] # Replace with the IP address to block
#     }

#     action = "Block"
#   }
}

# Create the Application Gateway
resource "azurerm_application_gateway" "secure_workload_appgw" {
  name                = "secure-workload-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name

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
    port = 80
  }

  # Define the backend address pool with IP addresses
  backend_address_pool {
    name         = "appgw-backend-pool"
    fqdns        = ["fs99-frontend-secure-workload.azurewebsites.net"] # Replace with your backend FQDNs
  }

  # Configure backend HTTP settings
  backend_http_settings {
    name                  = "appgw-backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
    pick_host_name_from_backend_address = true
  }

  # Define the HTTP listener
  http_listener {
    name                           = "appgw-http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "appgw-frontend-port"
    protocol                       = "Http"
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