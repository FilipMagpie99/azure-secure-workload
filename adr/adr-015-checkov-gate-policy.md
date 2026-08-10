# ADR 015: Checkov findings are triaged into fix, documented skip, or dated backlog; the gate hardens when the backlog closes

Status: accepted (Day 11)

## Context

The first pipeline scan returned 36 failed checks. Fixing everything blindly is tutorial behavior, ignoring everything makes the scanner decorative.

## Decision

Every finding lands in one of three classes:

1. Fix, when the change is cheap and aligned with the project thesis. Examples from the first triage: App Service HTTP logging and health checks (the thesis is that hardening produces observable signals, so services that do not log fail the thesis, not just the check), Application Gateway TLS policy, NSG on the private endpoint subnet, blob soft delete on the log storage.
2. Documented skip, as an inline `#checkov:skip=<ID>:<rationale>` annotation next to the resource. The rationale states the trade-off (lab cost, out-of-scope feature) or, for false positives, the evidence including the scanner version. The annotations are part of the public repository on purpose.
3. Backlog, for findings that are real but require an experiment or an architectural decision. These keep failing in the report as open items with a named closing path (Key Vault and log storage network hardening).

`--soft-fail` remains only until the backlog closes. Then the gate goes hard and any new finding blocks merge.

## Rejected alternative

Immediate hard fail with skips for everything not fixed. Reason: it would force writing skip annotations for items that are genuinely open, which turns documented risk acceptance into noise and hides the backlog.

## Consequences

First triage result: 58 passed, 20 skipped with rationale, 6 open. The scan caught one real regression between runs (SKU downgrade), which validated the gate. Scanner disagreements are resolved empirically with single-check local runs, not by trusting either the docs or the scanner.
