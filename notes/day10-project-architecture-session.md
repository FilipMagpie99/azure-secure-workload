# Day 10 — architecture design session (decisions, not code)

## Cheat sheet
```sql
-- Azure SQL: Entra identity + least-privilege INSIDE the DB (separate layer from Azure RBAC)
CREATE USER [appservice-secure-workload] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [appservice-secure-workload];
ALTER ROLE db_datawriter ADD MEMBER [appservice-secure-workload];
-- AI (when it lands): read-only
CREATE USER [ai-secure-workload] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [ai-secure-workload];
-- NEVER: db_owner / db_securityadmin / db_accessadmin
```
```hcl
# App Service -> SQL/KV: connection auth via MI, NO password in config
# public_network_access_enabled = false   <- PE is not enough, must also cut public access
# Key Vault: RBAC authorization model (NOT access policies)
#   runtime MI role = "Key Vault Secrets User"  (read values, not manage vault)
```

## Notes — decisions locked
- **D0 — workload**: universal stateful web app, full lifecycle. Security-pipeline idea -> project #2.
  - Defense: richest threat surface = most defense layers to demonstrate.
- **D1 — Compute**: App Service (PaaS), v1. Defense: native Azure over K8s; consistent with SC-500/Azure line.
  - AKS excluded *by* the "native Azure" choice itself = v2 scope. No separate argument needed.
  - PaaS shifts threat surface, doesn't remove it: SCM/Kudu endpoint, default public endpoint, app settings as leak vector, TLS/FTP knobs. Taken deliberately because each has a detection signal.
- **D2 — Data**: Azure SQL Database (PaaS single DB), v1. Defense: MS SQL familiarity + popularity (keyword for MS-heavy / banking).
  - SQL vs Postgres Flexible was near-equivalent from a security view (both PE/MI/TDE/logs). Narrative decision, not technical.
  - Auth: MI + Entra, no password in config. Password in app settings = leak vector ruled out by baseline.
  - Grants: db_datareader + db_datawriter = least-privilege FOR THIS workload (stateful app must write).
- **D3 — Identity + secrets**:
  - System-assigned MI, PER CONSUMER. App Service: own MI (read+write). AI: own MI (read-only).
  - Separate identities, NOT one shared user-assigned — different permission profiles; a shared identity would have to sum permissions and grant AI excess write.
  - Key Vault: RBAC model (not access policies). Runtime MI role = "Key Vault Secrets User".
  - Deployment principal (grants roles) != runtime MI (reads secrets) — separate identities.
- **D4a — Network segmentation**: single VNet, subnet segmentation (snet-app / snet-data / snet-pe), NSG + ASG at L3/L4.
  - Front/back = layers of one app -> subnet is the right boundary; separate VNets = overengineering + peering/routing cost.
  - ASG groups NICs for IP-independent NSG rules — it is addressing abstraction, NOT a filtering layer.
- **D4b — Ingress/egress per component (direction of initiation)**:
  - Front: ingress = HTTPS from internet (only thing exposed); egress -> backend (VNet integration).
  - Backend: ingress <- front only (private endpoint); egress -> SQL/KV (VNet integration).
  - SQL/KV: ingress <- backend only (private endpoint each); no meaningful egress.
  - Backend INITIATES to SQL/KV; responses return in the same connection (stateful) — no separate inbound rule.

## Log source map (needed for D5 anyway)
- RBAC role grant (control-plane) -> Activity Log -> `AzureActivity`
- KV secret read (data-plane)      -> diagnostic settings -> `AzureDiagnostics`  (NOT on by default)
- Identity sign-in                 -> `SigninLogs` (Entra)
- Directory change (groups/apps)   -> `AuditLogs` (Entra)

## Gotchas — logic traps caught (these are interview questions)
- "read-only" is WRONG for a stateful app. The app MUST write. Least-privilege = least the workload NEEDS, not least that exists.
  - Blast-radius boundary is NOT read vs write. It is DML (data) vs DDL (schema) + admin. Excluding db_owner means a compromised identity touches data, not structure, and can't escalate.
- "Adding AI" pushes toward SEPARATING identities, not simplifying. Different profiles (App=RW, AI=R) -> separate system-assigned, not one shared user-assigned. Sharing would break least-privilege.
  - Blast radius split per consumer: compromising the exposed AI (takes prompts!) = read only. Compromising App Service = RW but less exposed.
- RBAC role grants land in Activity Log / `AzureActivity` (control-plane), NOT Entra logs. Secret reads land in `AzureDiagnostics` (data-plane) and are NOT on by default. Two threats, two sources, two KQL queries.
- "KV by design / every landing zone has one" = cargo cult. Defend by RISK: no transitional window where a secret sits in app settings because KV doesn't exist yet. (Also: this is a WORKLOAD landing IN a landing zone, not the landing zone itself.)
- Direction of INITIATION vs direction of DATA: backend initiates to SQL/KV, they respond in the same connection. Stateful firewall auto-allows the return — only initiation needs a rule. SQL/KV initiating outbound = anomaly (exfil / C2) = detection signal.
- Two VNets for front+back = wrong isolation boundary (those are app layers, not trust zones/environments).
- WAF = Application Gateway WAF or Front Door WAF (L7). Azure Load Balancer is L4, no WAF — wrong block.
- Every private endpoint needs private DNS (privatelink zone linked to VNet). DNS leads, public-access-disabled enforces — two independent layers. (Same gotcha as Days 1-5.)
- Sentinel sits ON the LA workspace — not a separate store. Stream to LA; Sentinel layers analytics rules + hunting on top.

## OPEN — remaining this session
- 4b: restate in own words (who initiates / egress / ingress / stateful return) — confirmation pending.
- 4c: WAF — Front Door vs Application Gateway; v1 or backlog.
- D5: observability / detection — CORE, go deepest (signals, KQL, alerts, Sentinel).
- D6: Azure Policy guardrails (deny public IP, enforce PE, encryption) — v1 vs backlog.
- D7: AI component — binary v1 vs backlog.
- D8: CI/CD policy-gate (OPA/conftest) — v1 vs backlog. (OIDC + Checkov/tfsec already locked.)
- FINAL deliverable: resource inventory for prod.terraform.tfstate -> architecture diagram.