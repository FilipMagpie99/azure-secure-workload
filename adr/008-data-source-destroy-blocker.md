# ADR 008: azuread_user data source is a hidden operational dependency

## Context

The PostgreSQL module uses data "azuread_user" to feed the Entra ID administrator (object
id and UPN). Data sources are read during every Terraform run, including destroy.
Terraform refreshes them before building the destroy plan.

I hit this in practice. With a stale Entra token (Continuous Access Evaluation,
TokenIssuedBeforeRevocationTimestamp), terraform destroy failed on reading the user. A
dependency that exists only to create the AD admin blocked the teardown of the whole
stack before touching any infrastructure.

## Decision

Keep the data source, document the failure mode and the operational fix:
az account clear && az login, then rerun.

A considered alternative: pass object_id and user_principal_name as input variables
instead of a data source. No reads during destroy, at the cost of maintaining those
values by hand. Not worth it for a single-operator lab. Worth revisiting if this module
ever runs in CI.

## Consequences

Known runbook entry: destroy failing on azuread_user means the token, not the
infrastructure.

The general lesson: a data source inside a module creates a hidden operational
dependency. Every run, including destroy, requires that source to be readable at that
moment.
