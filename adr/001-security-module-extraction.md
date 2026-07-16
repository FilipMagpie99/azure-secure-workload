# ADR 001: Extract Key Vault, UMI and certificate into a dedicated security module

## Context

Key Vault, the App Gateway certificate, the user-assigned managed identity and its role
assignments originally lived in the compute module. Their only consumer (Application
Gateway) lives in the network module. This created a two-way dependency: network consumed
the identity and certificate from compute, while compute consumed subnets from network.

Terraform handled this fine because cycles are resolved at the resource level, not the
module level. But the module graph had a loop in it and there was no clean way to describe
the architecture as layers.

## Decision

I've moved Key Vault, the Key Vault role assignments, the UMI creation and the cert
generation to a new module called security. Module edges are now one-directional:
security to network, network to compute.

The migration was done with moved blocks in the root module, so nothing was destroyed or
recreated. terraform plan after the refactor showed only address moves and zero
infrastructure changes. This matters especially for Key Vault, which has soft-delete and
a static name.

## Consequences

Each module can now be described in one sentence and there is no dependency loop between
modules. Future application secrets will go into the security module as well. moved blocks
are now a proven pattern in this repo for refactoring without touching live
infrastructure.
