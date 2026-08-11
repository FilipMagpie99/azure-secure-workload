# ADR 014: Grants for workload identities stay in IaC, grants for people live in the bootstrap

Status: accepted (Day 11)

## Context

Introducing a second deploying identity (the pipeline) exposed two defects that were invisible with a single operator.

First, the stack granted Key Vault Certificates Officer to `data.azurerm_client_config.current.object_id`. "Current identity" is execution-context dependent: locally it resolves to me, in the pipeline it resolves to the managed identity. The first pipeline plan would have replaced the assignment, taking the role away from me and granting it to itself.

Second, `data "azuread_user" "current"` fed the PostgreSQL Entra administrator block from a Graph lookup of the current identity. In the pipeline this fails regardless of Graph permissions, because the lookup targets a user object and a service principal is not one. It was also the known destroy blocker.

The role itself turned out to be a deployer requirement, not a portal convenience: whoever runs apply manages the certificate resource and needs certificate data plane rights at apply time.

## Decision

The stack no longer grants roles to people or to whatever identity happens to run Terraform. The Certificates Officer grant moved to the bootstrap, assigned at resource group scope to both deployers (me and the pipeline identity). The `azuread_user` data source is removed and the PostgreSQL Entra administrator is set from explicit variables (object ID and UPN). The `azuread` provider is removed from the configuration. The grant for the Application Gateway identity remains in the stack, because that identity is part of the workload architecture.

## Rejected alternative

Keeping the lookup and granting the managed identity Graph read permissions. Reason: it adds a permission surface for a single lookup, it does not fix the user-object type mismatch, and it keeps configuration coupled to the executing identity.

## Consequences

Distinguish holding from granting: the pipeline holds Certificates Officer but cannot grant it, so the RBAC Administrator condition whitelist shrank to one GUID. A full stack destroy no longer depends on the directory. The rule going forward: identity of the operator must never leak into the desired state.
