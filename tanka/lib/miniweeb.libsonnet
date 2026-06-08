local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';

{
  local miniweeb = self,
  // Import images lib so apps don't need to import it separately
  // It is a separate lib to make scripting updates to it easier
  local imageLib = import 'images.libsonnet',
  images: imageLib.images,

  name: 'miniweeb',
  apiServerUri: 'https://%s.%s:6443' % [miniweeb.name, homelab.defaultDomain],
  ipv4: {
    api: '10.1.69.150',
    bind9: '10.2.69.12',
    pihole: '10.2.69.13',
  },

  // Cluster constants
  fs_ephemeral_storage_class: 'fs-ephemeral',
  defaultStorageClass: error 'Define defaultStorageClass for miniweeb cluster',
  nginxIngressClass: 'nginx',
  clusterCidrs: {
    podCidr: '10.69.40.0/22',
    serviceCidr: '10.69.44.0/22',
  },

  defaultAppConfig: utils.appConfig + {
    configVolStorageClass: miniweeb.defaultStorageClass,
    primaryDomains: homelab.allDomains,
    ingressClass: miniweeb.nginxIngressClass,
  },

  // Inline Tanka environment
  newTankaEnv(envName, namespace, data):: 
    utils.newTankaEnv(self, namespace, data),
}