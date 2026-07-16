# ADR 004: Keep VNet flow logs despite limited coverage in a PaaS-only topology

## Context

VNet flow logs are collected from actual NICs in the VNet. Because I'm using PaaS
resources, there are almost no NICs here. App Service is explicitly unsupported by flow
logs and App Gateway v2 instances are managed by the platform. The only classic NICs in
this VNet belong to the private endpoints, so flow visibility is limited to traffic
reaching those PE NICs.

## Decision

I've decided to keep the flow log on the VNet and document the limitation instead of
pretending it gives full network telemetry.

## Consequences

Flow logs currently give partial visibility (PE-side traffic). The real request-level
telemetry for this stack comes from App Gateway access and WAF logs plus App Service
IPSecAuditLogs.

It may be good to keep them for future development, for example adding VMs to my VNet.
The moment IaaS lands here, flow logs start working with no extra effort.
