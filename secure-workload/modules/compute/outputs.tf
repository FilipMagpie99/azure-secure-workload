output "frontend_MI" {
  value = azurerm_linux_web_app.frontend_secure_workload.identity[0].principal_id
}

output "backend_MI" {
  value = azurerm_linux_web_app.backend_secure_workload.identity[0].principal_id
}

output "frontend_app_service_id" {
  value = azurerm_linux_web_app.frontend_secure_workload.id
}

output "backend_app_service_id" {
  value = azurerm_linux_web_app.backend_secure_workload.id
}