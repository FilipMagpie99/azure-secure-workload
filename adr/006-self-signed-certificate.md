# ADR 006: Self-signed TLS certificate generated in Key Vault

## Context

The App Gateway HTTPS listener needs a certificate. A publicly trusted certificate
requires a domain I'd have to buy and validate. A public CA won't issue a cert for a bare
IP address.

## Decision

The TLS cert is self-signed for the purpose of this project, generated directly in Key
Vault (issuer_parameters set to Self), so the private key never touches my laptop or the
repo. The logic is replaceable: if I were to buy a domain and get an actual CA-signed
cert, it's a change of one issuer_parameters block and the whole lifecycle mechanism
stays the same.

The cert auto-renews 30 days before expiration (lifetime_action) and App Gateway picks up
new versions automatically through the versionless secret id and its polling (roughly
every 4 hours).

It must be exportable due to App Gateway requirements. The gateway reaches the cert via
the secrets path and needs access to the private key to use it for TLS. Compensation for
that: data plane access is limited to a single user-assigned identity with Key Vault
Secrets User on this vault only, and every secret read lands in the AuditEvent log in Log
Analytics.

## Consequences

Browsers show the connection as untrusted. That's about identity, not encryption. The
session is encrypted the same as with a CA cert. Expected in a lab, tests use curl -k.

Certificate rotation is fully automated and requires no Terraform run.

The production path is documented and cheap: CA issuer plus a domain, zero architecture
changes.
