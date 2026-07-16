# ADR 003: Remove Application Security Groups from the project

## Context

Two ASGs (asg-front, asg-back) were present from the beginning of the project, created
back when the early labs ran on virtual machines.

## Decision

I've deleted the ASGs. ASG would be a good move if I were grouping NICs and actually
applying NSG rules to those groups. That's not the case here, because this project is
based almost entirely on PaaS resources, so there are no VM NICs to group. Traffic
isolation is already handled by private endpoints and VNet integration.

## Consequences

Less dead code in the repo. No resources that look like controls but don't express
anything.

ASGs come back the moment IaaS or AKS enters the picture (planned as v2). The concept is
deferred, not rejected.
