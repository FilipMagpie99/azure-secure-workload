data "azurerm_policy_definition" "appsvc_https_only" {
  name = "a4af4a39-4135-47fb-b175-47fbdf85311d"
}

resource "azurerm_resource_group_policy_assignment" "appsvc_https_only" {
  name                 = "audit-appsvc-https-only"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.appsvc_https_only.id

  display_name = "App Service apps should only be accessible over HTTPS"
  description  = "Audit-then-enforce: Audit do czasu wdrozenia pakietu HTTPS end-to-end, potem flip na Deny (ADR-XX)"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })

  non_compliance_message {
    content = "App Service must enforce HTTPS-only. See ADR-XX."
  }
}