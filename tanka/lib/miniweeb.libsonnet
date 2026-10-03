local clusterBase = import 'cluster-base.libsonnet';
local homelab = import 'homelab.libsonnet';

clusterBase.makeCluster({
  name: 'miniweeb',
  domain: 'miniweeb.local',
  tlsEnabled: false,
  apiServerUri: 'https://api.%s:6443' % [self.domain],
  ipv4: {
    api: '192.168.49.100',
    ingress: '192.168.49.11',
    bind9: '192.168.49.12',
    pihole: '192.168.49.13',
  },

  // Cluster constants
  fs_ephemeral_storage_class: 'fs-ephemeral',
  defaultStorageClass: 'csi-hostpath-sc',
  snapshotClass: 'csi-hostpath-snapclass',
  nginxIngressClass: 'nginx',
  clusterCidrs: {
    podCidr: '10.244.0.0/16',
    serviceCidr: '10.96.0.0/12',
  },

  metallb: {
    mode: 'l2',
    addresses: ['192.168.49.2-192.168.49.99'],
  },
})