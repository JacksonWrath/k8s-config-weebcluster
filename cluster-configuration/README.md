# Cluster Setup (k3s)

If recreating the cluster, the following are some cluster-level / one-time steps to be performed.

## Ceph OSD device classes

In my environment at least, Ceph comes up with the NVMe drives marked as the `ssd` device class instead. This can be fixed with the Krew plugin (or the toolbox):

```
kubectl rook-ceph ceph osd crush rm-device-class osd.0 osd.1 osd.2 osd.3 osd.4 osd.5

kubectl rook-ceph ceph osd crush set-device-class nvme osd.0 osd.1 osd.2 osd.3 osd.4 osd.5
```

## external-snapshotter
After initially setting up Rook, external-snapshotter needs to be set up. See here for more info:

https://rook.io/docs/rook/latest-release/Storage-Configuration/Ceph-CSI/ceph-csi-snapshot/

## system-upgrade-controller

Install the k3s automated upgrade controller:

https://docs.k3s.io/upgrades/automated#install-the-system-upgrade-controller