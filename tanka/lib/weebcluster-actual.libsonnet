local clusterBase = import 'cluster-base.libsonnet';
local homelab = import 'homelab.libsonnet';

clusterBase.makeCluster({
  name: 'weebcluster',
  domain: 'waifus.dev',
  apiServerUri: 'https://aomine.%s:6443' % [self.domain],
  ipv4: {
    api: '10.1.69.101',
    aomine: '10.1.69.101',
    kagami: '10.1.69.102',
    kuroko: '10.1.69.103',
    ingress: '10.2.69.1',
    bind9: '10.2.69.10',
    pihole: '10.2.69.11',
  },

  // Cluster constants
  nvme_storage_class: 'nvme-rook-ceph',
  fs_ephemeral_storage_class: 'fs-ephemeral',
  defaultStorageClass: self.nvme_storage_class,
  snapshotClass: 'csi-rbdplugin-snapclass',
  nginxIngressClass: 'nginx',
  clusterCidrs: {
    podCidr: '10.69.20.0/22',
    serviceCidr: '10.69.24.0/22',
  },

  metallb: {
    mode: 'bgp',
    addresses: ['10.2.69.1-10.2.69.250'],
    bgp: {
      myASN: 65003,
      peerASN: 65001,
      peerAddress: '10.1.69.254',
    },
  },
})
