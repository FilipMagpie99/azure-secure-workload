resource "azurerm_service_plan" "secure-app_service_plan" {
    name = "secure-app-service-plan"
    location = var.location
    resource_group_name = var.resource_group_name
    os_type = "Linux"
    sku_name =  "S2"
}

resource "azurerm_linux_web_app" "frontend_secure_workload" {
    name = "fvt-frontend-secure-workload"
    location = var.location
    resource_group_name = var.resource_group_name
    service_plan_id = azurerm_service_plan.secure-app_service_plan.id
    virtual_network_subnet_id = var.subnet_id_app

    site_config {
         vnet_route_all_enabled = true
         ftps_state = "Disabled"
         minimum_tls_version = "1.2"
    }

    identity{
        type ="SystemAssigned"
    }

}

resource "azurerm_linux_web_app" "backend_secure_workload" {
    name = "fvt-backend-secure-workload"
    location = var.location
    resource_group_name = var.resource_group_name
    service_plan_id = azurerm_service_plan.secure-app_service_plan.id
    virtual_network_subnet_id = var.subnet_id_app
    site_config {
         vnet_route_all_enabled = true
         ftps_state = "Disabled"
         minimum_tls_version = "1.2"
    }

    identity{
        type ="SystemAssigned"
    }
}