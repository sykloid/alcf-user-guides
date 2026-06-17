# Hermes

Hermes is an Artemis cluster for use by ALCF staff members.

## Hardware

Hermes consists of 3 control plane nodes and 6 data plane nodes.

### Data Plane

| Component | Specification |
|---|---|
| Server | Dell PowerEdge R6615 |
| CPU | AMD EPYC 9334, 2.70 GHz, 32 cores / 64 threads, 128 MB cache (210W) |
| Memory | 128 GB DDR5-4800 (8x 16 GB RDIMM, 4800 MT/s, single rank) |
| Boot Storage | BOSS-N1 controller, 2x M.2 480 GB (RAID 1) |
| Network | 2x NVIDIA ConnectX-7 dual-port (MT2910), 200 Gb InfiniBand / Ethernet; 2x Broadcom BCM5720 1 GbE (management) |
| Power | Dual redundant (1+1) hot-plug, 1100W (100–240 VAC) |

## Storage

Persistent storage for the cluster is provided by the `camel` NetApp appliance. When creating PersistentVolumeClaims, specify `camel-nfs` as the storage class:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-data
spec:
  storageClassName: camel-nfs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
```
