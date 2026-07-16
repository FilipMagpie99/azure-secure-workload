# ADR 005: Pin the PostgreSQL availability zone explicitly in HCL

## Context

I didn't declare zone on the PostgreSQL Flexible Server, so Azure picked a zone by itself
at creation time (3). On a later plan the provider compared the config (declares nothing)
against the server (has zone 3) and tried to remove the zone. ARM rejects that, because
the zone of a Flexible Server can only be changed through an HA failover exchange with
the standby zone. The apply failed with:

zone can only be changed when exchanged with the zone specified in
high_availability.0.standby_availability_zone

## Decision

I've pinned zone = "3" in HCL. The config follows what the live API reported, checked
with az postgres flexible-server show --query availabilityZone.

## Consequences

Plans are clean, no destructive diff against a value Azure chose for me.

The general lesson: omitting an optional argument does not mean "leave it as is". For
some arguments the provider treats absence as "set it to empty" and generates a
destructive diff against the value the cloud picked on its own.

One trade-off to remember: a pinned zone can fail creation on a fresh deploy if that zone
has no capacity in the region at that moment.
