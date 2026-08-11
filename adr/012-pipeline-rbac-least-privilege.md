# ADR 013: Pipeline RBAC uses Contributor plus a conditioned RBAC Administrator, not Owner

Status: accepted (Day 11)

## Context

The stack creates a resource group, assigns one role (Key Vault Secrets User for the Application Gateway identity), reads and writes remote state over AAD data plane auth, and manages a Key Vault certificate.

## Decision

The pipeline identity holds four grants:

1. Contributor at subscription scope, because the stack creates the resource group.
2. Role Based Access Control Administrator at subscription scope with a condition restricting grantable roles to a whitelist containing only the Key Vault Secrets User definition GUID. The pipeline can create the one role assignment the stack declares and nothing else.
3. Storage Blob Data Contributor on the state storage account, because the backend uses AAD auth and control plane roles do not grant data plane access.
4. Key Vault Certificates Officer at workload resource group scope, because the stack manages a certificate resource and certificate operations are data plane. RG scope avoids a second chicken-and-egg problem, since the vault does not exist at bootstrap time and the role inherits onto it.

## Rejected alternative

Owner at subscription scope. Reason: Owner grants unrestricted role assignment, which means a code change adding `azurerm_role_assignment` could escalate any identity to any role, reviewable only by humans. The condition enforces the same restriction one layer below code review.

## Deferred

Splitting plan and apply into two identities (read-only for PR plan, write for apply on main). Extending the condition to `roleAssignments/delete`, which will surface at the first destroy or replace of the assignment from the pipeline.
