## Architecture

```mermaid
flowchart TB
    inet([Internet])

    inet -->|":80 HTTP → 301 redirect"| appgw
    inet -->|":443 TLS #1 — cert from KV"| appgw

    subgraph vnet["VNet secure-workload-vnet · 10.1.0.0/16"]
        subgraph sgw["snet-appgw 10.1.5.0/24 · SE: Microsoft.Web"]
            appgw["App Gateway WAF_v2
            OWASP 3.2 · Detection mode
            UMI + cert from Key Vault"]
        end
        subgraph sapp["snet-app 10.1.2.0/28 · delegation: serverFarms"]
            fe["frontend (App Service)
            ip_restriction: snet-appgw only"]
            be["backend (App Service)
            main site: Deny all · SCM: dev IP only"]
        end
        subgraph spe["snet-pe 10.1.4.0/28"]
            pe1["PE: backend/sites"]
            pe2["PE: postgres"]
        end
    end

    appgw -->|":443 TLS #2 · service endpoint"| fe
    fe -->|"private DNS → PE"| pe1 --> be
    be --> pe2 --> pg[("PostgreSQL Flexible
    Entra-only auth · public access: off · zone 3")]

    umi["UMI: appgw_identity"] -->|"RBAC: Key Vault Secrets User"| kv["Key Vault (RBAC model)
    appgw-listener-cert · AutoRenew 30d before expiry"]
    kv -.->|"4h polling · versionless secret id"| appgw

    z1["privatelink.azurewebsites.net"] -.-> pe1
    z2["privatelink.postgres.database.azure.com"] -.-> pe2

    law[("Log Analytics
    law-secure-workload-v2 · 30d retention")]
    appgw -.->|"AGWFirewallLogs · AGWAccessLogs"| law
    fe -.->|"IPSecAuditLogs · HTTPLogs"| law
    be -.->|"IPSecAuditLogs · HTTPLogs"| law
    pg -.->|"PostgreSQLLogs"| law
    sub(["Subscription Activity Log"]) -.->|"Administrative · Security · Policy"| law

    nw["Network Watcher + VNet flow log"] -.->|"blob storage · 90d retention"| st["Storage: workloadnetworkfs2123"]
```

**Legend:** solid lines — network traffic & identity · dashed lines — DNS resolution & telemetry