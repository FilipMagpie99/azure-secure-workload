# ADR 002: Key Vault stays reachable over public network (no private endpoint)

## Context

Key Vault could be put behind a private endpoint like PostgreSQL and the backend app.
The problem is that I deploy the certificate into Key Vault with Terraform from my
laptop. If I disabled public access, I wouldn't be able to deploy the certificate from
outside the VNet. It's the same situation as with SCM access for the frontend and
backend apps.

## Decision

I've decided to leave Key Vault open on the network layer. There is still an
authentication and authorization layer between anyone on the internet and my Key Vault,
which is the RBAC model. I had to directly assign myself a data plane role
(Key Vault Certificates Officer) to manage certificates, even though I'm the Owner of the
subscription. Owner alone gives no data plane access. App Gateway reaches the certificate
through its own user-assigned identity with Key Vault Secrets User, scoped to this vault
only.

## Consequences

Deploys from a developer machine keep working without a VPN or a self-hosted runner.

Compensating controls: RBAC is limited to two principals, and AuditEvent diagnostic logs
go to Log Analytics, so every data plane operation on the vault is visible.

In a production setup this would change: private endpoint plus
public_network_access_enabled = false, with deploys running from inside the network
(self-hosted runner or a jump host).
