# ADR 011: GitHub Actions authenticates to Azure with OIDC federation, not a service principal secret

Status: accepted (Day 11)

## Context

The CI/CD pipeline needs an identity to read remote state and run plan and apply against the subscription. The common tutorial approach stores a service principal client secret in GitHub Secrets.

## Decision

I use a user-assigned managed identity with two federated credentials trusting GitHub's OIDC issuer. The workflow requests a short-lived JWT from GitHub, Entra ID verifies the signature and string-matches the subject claim, and exchanges it for an Azure token. No credential is stored anywhere.

Two subjects map to two trust levels on the same identity: `repo:FilipMagpie99/azure-secure-workload:pull_request` covers plan on pull requests, `repo:FilipMagpie99/azure-secure-workload:ref:refs/heads/main` covers apply after merge. The PR subject intentionally carries no branch name, because pull requests are only trusted to plan. Trust narrows as privileges grow.

## Rejected alternative

Service principal with a client secret in GitHub Secrets. Reason: it is a long-lived credential stored in a third-party system, it requires rotation, and a repository or Actions compromise leaks a directly usable secret. The blast radius of the OIDC design under the same compromise is near zero, because the trust configuration lives in Entra, not in the repository.

## Consequences

The provider and the backend authenticate independently, so `use_oidc = true` is set in both. Terraform's azurerm provider performs the token exchange natively, so the workflow has no login step. The `ARM_CLIENT_ID`, `ARM_TENANT_ID` and `ARM_SUBSCRIPTION_ID` values are stored as plain repository variables, because they are not secrets and are useless without a valid federated token.
