# ADR 007: User-assigned identity for App Gateway, system-assigned for web apps

## Context

The stack uses two managed identity models side by side and the choice was deliberate.

## Decision

UMI is a user-assigned managed identity, independent of the lifecycle of the resource
it's attached to. That makes sense for certificate access: the identity and its Key Vault
role can outlive the gateway, and the same identity could be used by multiple services I
own that need the same cert.

On the other hand, resources such as the web apps get granular permissions to other
resources. Those permissions should disappear when the resource is gone, with no orphaned
role assignments left to clean up. This is the use case for system-assigned managed
identity, whose lifespan is the same as the lifespan of the resource it's assigned to.

## Consequences

App Gateway can be destroyed and recreated (cost control in the lab) without touching the
identity or waiting for Key Vault RBAC to propagate again.

Web app identities and their future role assignments die with the apps, so there is no
orphaned RBAC.

Both models live in one repo with a concrete reason for each.
