resource "azurerm_log_analytics_workspace" "law_secure_workload" {
  name                = "law-secure-workload-v2"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "diag-app-to-law-secure-workload" {
  for_each                       = var.app_service_ids
  name                           = "diag-app-to-law-secure-workload"
  target_resource_id             = each.value
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law_secure_workload.id
  log_analytics_destination_type = "Dedicated"

  enabled_metric {
    category = "AllMetrics"
  }
  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }
  enabled_log {
    category = "AppServiceHTTPLogs"
  }

}

resource "azurerm_monitor_diagnostic_setting" "diag-sub-to-law-secure-workload" {
  name                           = "diag-sub-to-law-secure-workload"
  target_resource_id             = "/subscriptions/${var.subscription_id}"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law_secure_workload.id
  log_analytics_destination_type = "Dedicated"

  enabled_metric {
    category = "AllMetrics"
  }
  enabled_log {
    category = "Administrative"
  }
  enabled_log {
    category = "Security"
  }
    enabled_log {
    category = "Policy"
  }
} 


resource "azurerm_monitor_diagnostic_setting" "diag-postgres-to-law-secure-workload" {
  name                           = "diag-postgres-to-law-secure-workload"
  target_resource_id             = var.postgres_server_id 
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law_secure_workload.id
  log_analytics_destination_type = "Dedicated"

  enabled_metric {
    category = "AllMetrics"
  }
  enabled_log {
    category = "PostgreSQLLogs"
  }
} 


resource "azurerm_monitor_diagnostic_setting" "diag-appgw-to-law-secure-workload" {
  name                           = "diag-appgw-to-law-secure-workload"
  target_resource_id             =  var.secure_workload_appgw_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law_secure_workload.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  enabled_log{
    category = "ApplicationGatewayAccessLog"
  }
} 