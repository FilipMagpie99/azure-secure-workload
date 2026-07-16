output "appgw_cert_versionless_secret_id" {
  value = azurerm_key_vault_certificate.appgw_cert.versionless_secret_id
}

output "kv_id" {
  value = azurerm_key_vault.kv_secure_workload.id
}

output "appgw_identity_id" {
  value = azurerm_user_assigned_identity.appgw_identity.id
}