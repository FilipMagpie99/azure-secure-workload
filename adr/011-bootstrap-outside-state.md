# ADR 012: Pipeline identity and its permissions live outside the Terraform state they operate on

Status: accepted (Day 11)

## Context

If the identity that runs the pipeline is itself a resource in the stack the pipeline manages, two problems appear. First, a chicken-and-egg problem: someone has to run the first apply before the identity exists. Second, a self-referential blast radius: the pipeline could modify or destroy its own identity and trust configuration.

## Decision

The user-assigned managed identity, its federated credentials, its role assignments, the remote state storage and the repository variables form a bootstrap layer created with the Azure CLI, outside Terraform state. The layer is codified as `scripts/bootstrap.sh`, which also serves as its documentation and makes tenant resets a single command.

## Rejected alternative

Managing the identity in the same stack. Reason: the two problems above. A separate small bootstrap Terraform stack with local state was also considered and deferred, because a shell script is sufficient at this scale and adds no state to protect.

## Consequences

After a tenant reset the bootstrap is reproducible. The pipeline cannot escalate or destroy its own identity through a code change, because that identity is not in its state. The cost is one imperative script that must be kept in sync with what the stack expects (state storage name in the backend block, dev IP secret).
