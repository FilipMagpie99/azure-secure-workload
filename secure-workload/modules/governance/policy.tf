data "azurerm_policy_definition" "appsvc_https_only" {
  name = "a4af4a39-4135-47fb-b175-47fbdf85311d"
}



resource "azurerm_resource_group_policy_assignment" "appsvc_https_only" {
  name                 = "audit-appsvc-https-only"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.appsvc_https_only.id

  display_name = "App Service apps should only be accessible over HTTPS"
  description  = "Audit-then-enforce: first audit, then deny"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })

  non_compliance_message {
    content = "App Service must enforce HTTPS-only."
  }
}

data "azurerm_policy_definition" "pgsql_svflex_entraonly_auth" {
  name = "fa498b91-8a7e-4710-9578-da944c68d1fe"
}

resource "azurerm_resource_group_policy_assignment" "pgsql_svflex_entraonly_auth" {
  name                 = "audit-pgsql-svflex-entraonly-auth"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.pgsql_svflex_entraonly_auth.id

  display_name = "[Preview]: Azure PostgreSQL flexible server should have Microsoft Entra Only Authentication enabled"
  description  = "Audit-then-enforce: first audit, then deny"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })

  non_compliance_message {
    content = "PostgresSQL server must use Entra authentication only."
  }

}