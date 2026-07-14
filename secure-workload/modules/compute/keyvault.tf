data "azurerm_client_config" "current1" {}

resource "azurerm_key_vault" "kv_secure_workload" {
  name                       = "kv-secure-workload"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current1.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  rbac_authorization_enabled = true
}

resource "azurerm_key_vault_certificate" "appgw_cert" {
  name         = "appgw-listener-cert"
  key_vault_id = azurerm_key_vault.kv_secure_workload.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_type   = "RSA"
      key_size   = 2048
      reuse_key  = false
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    x509_certificate_properties {
      subject            = "CN=secure-workload.lab"
      validity_in_months = 12
      key_usage = [
        "digitalSignature",
        "keyEncipherment",
      ]
      subject_alternative_names {
        dns_names = ["secure-workload.lab"]
      }
    }
    lifetime_action {
      action { action_type = "AutoRenew" }
      trigger { days_before_expiry = 30 }
    }
  }
    depends_on = [azurerm_role_assignment.deployer_kv_certificates_officer]
}

#User assigned managed identity for the Application Gateway to authenticate to Key Vault and retrieve the certificate
resource "azurerm_user_assigned_identity" "appgw_identity" {
  location            = var.location
  name                = "appgw_identity"
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "appgw_identity_keyvault_reader" {
  scope                = azurerm_key_vault.kv_secure_workload.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.appgw_identity.principal_id
}

#assigning permission to the current user (terraform) to manage certificates in the Key Vault
resource "azurerm_role_assignment" "deployer_kv_certificates_officer" {
  scope                = azurerm_key_vault.kv_secure_workload.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.current1.object_id
}