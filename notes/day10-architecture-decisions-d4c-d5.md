# Day 10 — architecture design session (cont. D4c–D5)

## Notes — decisions locked (cont.)
- **D4c — WAF**: Application Gateway WAF v2 in VNet (snet-appgw), v1.
  - Defense: L7 content inspection. NSG stops at L4 — sees "front to back on 443" but not SQLi in the body. OWASP Top 10 passes untouched without an L7 inspection point.
  - App Gateway (regional, in-VNet) over Front Door (global edge) — fits VNet-centric topology.
  - App Gateway TERMINATES TLS → becomes the L7 inspection point (it's the legit endpoint, not MITM on someone's tunnel). That's why it sees plaintext and NSG never does.
  - WAF is the ONLY public ingress. Front loses its public endpoint — reachable only from App Gateway.
    - Presence of WAF is NOT enough: front keeps its own *.azurewebsites.net public door unless explicitly cut. Two public doors = attacker takes the unprotected one. Must enforce public_network_access_enabled=false + access restriction to snet-appgw. WAF leads, public-access-disabled enforces.
  - Cost reconcile: App Gateway WAF v2 has hourly fixed cost (no auto-pause, unlike App Service/SQL serverless). Justified in v1 because build→demo→tear-down means it only bills during active sessions.
  - Updates D4b: front is no longer public.
- **D5 — Observability / detection**: CORE. Decision made; KQL implementation deferred to live data.
  - Detection-engineering discipline: explore data in Sentinel FIRST, write KQL on real schema/distribution, not on imagined data. ("validate baseline, then alert on deviation.")
  - Two phases: (1) DESIGN [this session] = which sources + which detection pillars — DONE. (2) IMPLEMENTATION [on built infra] = enable sources, generate traffic, explore in Sentinel, write KQL on live data.
  - Three pillars = a 2x2 matrix (control-plane vs data-plane) x (permissions vs network):

| | control-plane (who configured) | data-plane (what actually happened) |
|---|---|---|
| **permissions** | Pillar 1: role grants + NSG/resource writes (`AzureActivity`) | Pillar 2: identity used outside its profile (`AzureDiagnostics`) |
| **network** | (rule changes = variant of Pillar 1) | Pillar 3: traffic violating topology (NSG flow logs) |

  - Pillar 1 — privilege escalation / config change: `AzureActivity`, `Microsoft.Authorization/roleAssignments/write`, NSG writes. Catches *preparation*.
  - Pillar 2 — identity abuse: `AzureDiagnostics` (KV/SQL data-plane), crossed with each MI's DESIGNED profile (backend MI = RW SQL + R KV; AI MI = R SQL). MI outside profile = signal.
  - Pillar 3 — topology violation: NSG flow logs (data-plane). Catches *the actual event* even if no rule changed (misconfig, lateral movement, unforeseen path). Baseline from D4 IS the rule: traffic to snet-data from ≠snet-app, traffic to front from ≠snet-appgw, SQL initiating outbound = exfil/C2.
  - Why the matrix matters: systematic coverage of the "acquire privilege → use it" lifecycle, not three random rules.

## Gotchas (cont.)
- **Managed identity does NOT sign in with an IP.** No interactive sign-in, no source IP — token via IMDS (169.254.169.254, link-local, no client IP). "MI login from unknown IP" doesn't exist. Detect MI by BEHAVIOR (identity acting outside designed access profile, data-plane), not by source IP. (Ties to Days 1-5 gotcha: MI = SP, token via IMDS, passwordless.)
- **Control-plane vs data-plane for network**: changing an NSG rule = control-plane (`AzureActivity`, NSG write) — that's a variant of Pillar 1, NOT a third axis. Pillar 3 is data-plane: NSG flow logs showing real traffic. Data-plane catches what control-plane can't (attacker uses an existing gap without changing config).
- **Prevention vs detection are different layers, want both.** Azure Policy *prevents* (deny public IP). Detection *alerts* when something happens (e.g. if Policy is bypassed/disabled or change comes another way). Baseline enforcement leans Policy (→ D6); detection covers the gap.
- Explore-before-alert: rule written without validating baseline assumes infra works like the diagram. The drift between design and reality is itself a signal (terraform plan as continuous compliance, applied to network flow).

## OPEN — remaining
- D6: Azure Policy guardrails — which (deny public IP, enforce PE, require encryption), v1 vs backlog, and how Policy (prevention) + detection (D5) pair as two layers. [D5 pillar-1 idea "baseline enforcement" lands here.]
- D7: AI component — binary v1 vs backlog.
- D8: CI/CD policy-gate (OPA/conftest) — v1 vs backlog. (OIDC + Checkov/tfsec locked.)
- FINAL: resource inventory for prod.terraform.tfstate → architecture diagram.