#compute 

output "frontend_MI" {
  value = module.compute.frontend_MI
}

output "backend_MI" {
  value = module.compute.backend_MI
}

output "current_subscription_subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}

output "resource_group_id"{
  value = azurerm_resource_group.rg.id
}