# Backlog

Open items with a named owner of truth: what closes them and when. Dated on entry.

## Security hardening (Checkov open findings)

- **PR 2: shared key on flow log storage** (CKV2_AZURE_40) — added 2026-08-08.
  Break-and-observe: set `shared_access_key_enabled = false`, wait one flow log interval, check whether new blobs still arrive (`az storage blob list --auth-mode login`). Logs flow: finding closed. Logs stop: revert and skip with "verified empirically" and the date. Either outcome is a documented fact.
- **PR 3: Key Vault network hardening** (CKV_AZURE_109, CKV_AZURE_189, CKV2_AZURE_32) — added 2026-08-08.
  Variant C from triage: `network_acls` default Deny + dev IP + App GW subnet service endpoint, plus a workflow step that adds/removes the runner IP around plan/apply (hosted runner tax, documented in ADR when done). Then force cert refresh (App GW stop/start) to resolve the contradictory Microsoft docs empirically (PE vs service endpoint vs trusted services). Full PE + public off deferred until a self-hosted runner exists.
- **Log storage public access** (CKV_AZURE_59, CKV2_AZURE_33) — added 2026-08-08.
  Same deployer-access question as Key Vault; folds into PR 3 experiment or its follow-up.
- **Harden the gate**: switch Checkov from `--soft-fail` to hard fail — trigger: PR 2 and PR 3 merged.

## Pipeline

- `workflow_dispatch:` trigger on `apply.yml` for manual reruns without hunting run IDs — added 2026-08-08, one line.
- Split plan/apply into two identities (read-only PR identity) — deferred, ADR 013.
- Extend RBAC Administrator condition to `roleAssignments/delete` — trigger: first pipeline destroy/replace of a role assignment fails.
- Pin GitHub Actions by commit SHA instead of tag; consider Dependabot for action updates — deferred, supply chain note in Day 11.
- PR comment with rendered plan (`pull-requests: write` already granted) — stretch.

## Observability (feeds Day 12)

- Diagnostic settings for both App Services to Log Analytics (`azurerm_monitor_diagnostic_setting`); filesystem logs from PR 1 close the Checkov finding but the detection pack needs LAW tables.
- CI/CD identity detection: baseline `AADManagedIdentitySignInLogs` sign-ins against workflow run windows (GitHub API `run_id` correlation); alert on sign-ins outside any run and on failed token exchanges (broken subject = probe).
- Health check probes (added PR 1) emit availability signal; wire into detection pack.
- App GW WAF logs went silent mid-session previously; investigate before building detections on them.

## Refactors (non-blocking)

- Move PostgreSQL Entra admin variables to root module and pass into compute explicitly (defaults in module today, noted as debt on Day 11).
- Unify resource label convention (mix of hyphens and underscores); requires `moved {}` blocks, do not batch with functional changes.
- `health_check_path` currently `/` on both apps; switch to a real `/health` endpoint when the application is deployed.
- Verify pre-commit hooks installed on this machine (`pre-commit install`); fmt failed in CI because the hook was not active.
