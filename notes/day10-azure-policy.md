# PRtest
# Day 10 — Azure Policy: assignments, exemptions, evaluation model

## Cheat sheet

```bash
# find definitions by displayName (browsing only, verify by policyRule before use)
az policy definition list \
  --query "[?contains(displayName, 'PostgreSQL') && contains(displayName, 'flexible')].{name:name, display:displayName, deprecated:metadata.deprecated}" \
  -o table

# structural filter by resource type in the rule (slower, deterministic, no displayName noise)
az policy definition list \
  --query "[?contains(to_string(policyRule.if), 'Microsoft.KeyVault/vaults')].{name:name, display:displayName}" \
  -o table

# verify allowed effects BEFORE writing any assignment
az policy definition show --name <GUID> \
  --query "{display:displayName, effects:parameters.effect.allowedValues, default:parameters.effect.defaultValue}"

# if effects returns None, the effect is hardcoded — do not pass an effect parameter
az policy definition show --name <GUID> --query "policyRule.then.effect"

# read what the policy actually checks (authoritative, displayName lies by simplification)
az policy definition show --name <GUID> --query "policyRule"

# force evaluation instead of waiting for the background cycle
az policy state trigger-scan --resource-group rg-secure-workload

# compliance state per assignment
az policy state list --resource-group rg-secure-workload \
  --query "[?contains(policyAssignmentName, 'pna')].{resource:resourceId, compliant:complianceState, ts:timestamp}" \
  -o table

# compliance state via Resource Graph (my default read path, portal aggregates can mislead)
az graph query -q "policyresources | where type == 'microsoft.policyinsights/policystates' | project resource = tostring(properties.resourceId), state = tostring(properties.complianceState), assignment = tostring(properties.policyAssignmentName), ts = tostring(properties.timestamp)"

# exemptions on a resource scope are NOT returned by plain -g listing
az policy exemption list --scope <resource-id>
az policy exemption list --resource-group rg-secure-workload --disable-scope-strict-match

# live field check when compliance result looks wrong
az webapp show -n <app> -g <rg> --query "publicNetworkAccess"
```

## Notes

**Evaluation model.** All assignments evaluate in parallel. There is no override between scopes: a resource under Deny from MG and Audit from RG is subject to both. Effective result is the sum of all assignments, so the most restrictive effect wins. A lower-scope assignment can only tighten, never loosen. The only legal loosening path is an exemption: explicit, auditable, its creation is a `policyExemptions/write` event in Activity Log.

**Evaluation triggers.** Write on a resource: result within ~15 min. New/changed assignment: ~30 min propagation. Full background scan: 24 h. On demand: `trigger-scan`. The 24 h cycle is background, not the primary mechanism.

**DINE asymmetry.** Resources created AFTER the assignment are remediated automatically (write trigger). Resources existing BEFORE need a manual remediation task. Auto-remediation is not instant: the resource lives minutes without diag settings and everything from that window is unobservable forever. DINE is compensation, not prevention; the hard guarantee is config in the deployment itself (CI/CD policy check — Day 11 hook).

**Deny mechanics.** Deny fires on the ARM write payload. A condition is Deny-able only if it resolves from the request body alone. Existence of another resource (AINE family) is structurally not Deny-able; its hard counterpart is DINE or a pipeline check.

**Two staging knobs.** Effect in parameters (Audit/Deny) and `enforce` on the assignment (DoNotEnforce = even Deny only reports). Org rollout of a new Deny goes through enforce=false on the prod scope.

**Terraform mapping.** Built-ins: data source `azurerm_policy_definition` by GUID + `azurerm_resource_group_policy_assignment`. Custom would be `azurerm_policy_definition` as a resource. Exemption: `azurerm_resource_policy_exemption` referencing the assignment ID, resource-level scope via module outputs (`module.compute.frontend_app_id`), not by reaching into another module. Audit→Deny flip is a one-string update-in-place; the git history of those commits is the audit-then-enforce evidence.

**Exemption categories.** Mitigated = policy intent achieved by another mechanism. Waiver = risk accepted without compensation. The axis is whether the risk is addressed, not whether the state is temporary. `expires_on` optional for both; I skipped it because the compensating control is a property of the architecture.

**Scope.** RG-level assignment is correct for this lab (matches my blast radius). In an org the same initiative lives on a management group and inherits down; RG-level is for exceptions stricter than baseline or pilots. Network isolation (VNet) and policy scope are independent axes — do not mix them.

**Final state.** 4 assignments: HTTPS-only (Deny, tested via RequestDisallowedByPolicy), Postgres Entra-only (Audit, negative test passed), storage network restrict (Audit, caught a real finding, fixed, functionally verified), App Service PNA (Audit + 2 Mitigated exemptions, no expiry). ADR-XX documents selection, rejections, deferrals.

## 💡 Gotchas

- **Deprecated definitions get successors under new GUIDs**, sometimes with rebranding (AAD→Entra). Filter on `metadata.deprecated`, never on displayName. The Entra-only definition I assigned is [Preview] — accepted knowingly, the deprecated predecessor has no GA successor.
- **JMESPath `contains` is case-sensitive.** 'Key Vault' missed lowercase 'Key vaults' definitions and returned only Managed HSM (different product). Empty list → suspect casing first.
- **"Storage" in displayName often means the log DESTINATION**, not the governed resource ("Enable logging by category group ... to Storage"). displayName is for browsing, policyRule is for deciding.
- **Twin definitions with near-identical names must BOTH be verified by policyRule before assignment.** I assigned the wrong PNA twin (category "Mission", dot at the end of displayName) whose rule natively accepts PNA=Enabled + ACL default Deny — it silently voided my exemption narrative by marking Variant B compliant. The general twin (`1b5ef780`) checks the flag alone and behaves as my ADR assumed. Cost: one wasted apply and a false-green.
- **Exempt state carries no information about how the resource would evaluate.** Exemption is a blind spot in evaluation, not a conditional verdict. Do not infer "would be non-compliant" from Exempt.
- **Compliance state has a timestamp — without a fresh scan you read the past.** Always project `ts` in graph queries. Freshness of a signal is a property of the signal (same reason SOCs alert on missing logs).
- **Portal compliance blades can aggregate Exempt into green counts.** Resource Graph shows the granular truth. KQL over portal.
- **`az policy exemption list -g` is scope-strict**: resource-level exemptions are invisible without `--disable-scope-strict-match`. Policies inherit down, listing does not look down.
- **Storage `ip_rules` rejects /31 and /32.** Single host = bare IP, no mask. NSG and AppGW accept /32 fine — Azure has no single canonical IP format across APIs. One canonical CIDR variable + `split("/", var)[0]` local in the consuming module; comment the host-address assumption, a real range would silently change rule meaning.
- **HCL error ladder from one line:** bare `dev_ip` = parser reads a resource reference (vars always need `var.` prefix) → `"var.dev_ip"` in quotes = literal string sent to Azure → provider value validation rejects the format. Syntax → type → value validation → API. Read the error message to the end before mutating code; the fix was inside it every time.
- **Storage 403 in portal after default_action=Deny is the control working**, on me. Management plane (ARM: apply, az show, settings blade) unaffected; data plane (blob listing) blocked regardless of identity. Identity is not a network criterion.
- **Policy and Terraform drift are two independent detections of the same manual degradation.** The Postgres negative test tripped both: non-compliant in policy state, drift in plan.
- **Assignment propagation ~30 min.** Empty compliance right after apply is not a failure. Trigger-scan or coffee.
## 💡 Gotchas
- 
