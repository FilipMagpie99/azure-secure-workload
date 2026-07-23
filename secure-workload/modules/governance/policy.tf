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

data "azurerm_policy_definition" "storageacc_restrict_network_access" {
  name = "34c877ad-507e-4c82-993e-3452a6e0ad3c"
}


resource "azurerm_resource_group_policy_assignment" "storageacc_restrict_network_access" {
  name                 = "storageacc-restrict-network-access"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.storageacc_restrict_network_access.id

  display_name = "Storage accounts should restrict network access"
  description  = "Audit-then-enforce: first audit, then deny"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })

}

data "azurerm_policy_definition" "appsvc_pna_disabled" {
  name = "1b5ef780-c53c-4a64-87f3-bb9c8c8094ba"
}

resource "azurerm_resource_group_policy_assignment" "appsvc_pna_disabled" {
  name                 = "audit-appsvc-pna-disabled"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.appsvc_pna_disabled.id

  display_name = "App Service apps should disable public network access"
  description  = "Audit only. PNA=Enabled with ip_restriction default Deny. Exemption: ADR-XX"

  parameters = jsonencode({
    effect = { value = "Audit" }
  })
}

resource "azurerm_resource_policy_exemption" "frontend_pna_mitigated" {
  name                 = "exempt-pna-frontend"
  resource_id          = var.frontend_app_service_id
  policy_assignment_id = azurerm_resource_group_policy_assignment.appsvc_pna_disabled.id
  exemption_category   = "Mitigated"

  display_name = "PNA mitigated by ip_restriction default Deny + App Gateway path"
  description  = "Policy intent (no uncontrolled public path) achieved via ACLs: site and SCM default_action=Deny, application traffic exclusively through AppGW/WAF. Residual risk: endpoint still exists, attack surface = ACL parser + SCM reachable from admin IP. Accepted due to deployability requirement. See ADR-XX."
}

resource "azurerm_resource_policy_exemption" "backend_pna_mitigated" {
  name = "exempt-pna-backend"
  resource_id = var.backend_app_service_id
  policy_assignment_id = azurerm_resource_group_policy_assignment.appsvc_pna_disabled.id
  exemption_category = "Mitigated"

  display_name = "PNA mitigated by ip_restriction default Deny + App Gateway path"
  description  = "Policy intent (no uncontrolled public path) achieved via ACLs: site and SCM default_action=Deny, application traffic exclusively through AppGW/WAF. Residual risk: endpoint still exists, attack surface = ACL parser + SCM reachable from admin IP. Accepted due to deployability requirement. See ADR-XX."
}