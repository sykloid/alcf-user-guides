# Nepenthes

Nepenthes is an Artemis cluster for use by ALCF, CELS, and CSPO staff for
cybersecurity testing.

## Hardware

Nepenthes consists of 3 control plane nodes, 5 data plane nodes, and 2 egress
nodes. All nodes are virtual machines hosted on the ALCF hypervisor.

### Node Specifications

| Component    | Specification     |
|--------------|-------------------|
| vCPUs        | 2                 |
| Memory       | 8 GB              |
| Boot Storage | ~38 GB (ephemeral)|
| OS           | Talos v1.12.7     |

## Access

Access to Nepenthes is granted to members of the `alcf_c4` and
`cels_cybersecurity` LDAP groups, authenticated via Keycloak. To get started,
follow the [Artemis Getting Started guide](../../getting-started.md) with the
Nepenthes [kubeconfig](./user@nepenthes.kubeconfig.yml) file in place of the
Hermes one.
