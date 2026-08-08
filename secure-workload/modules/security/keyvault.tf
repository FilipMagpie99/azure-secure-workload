data "azurerm_client_config" "current" {
}

resource "azurerm_key_vault" "kv_secure_workload" {
  #checkov:skip=CKV_AZURE_110:Lab with frequent teardowns; purge protection blocks vault name reuse for retention period
  #checkov:skip=CKV_AZURE_42:Recoverability attribute same as CKV_AZURE_110; lab teardown trade-off
  name                       = "kv-secure-fs-workload"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
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

