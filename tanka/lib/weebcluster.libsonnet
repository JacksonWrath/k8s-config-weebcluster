local kube = import 'k.libsonnet';
local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';

{
  local weebcluster = self,

  // Import images lib so apps don't need to import it separately
  // It is a separate lib to make scripting updates to it easier
  local imageLib = import 'images.libsonnet',
  images: imageLib.images,

  // Cluster constants
  nvme_storage_class: 'nvme-rook-ceph',
  defaultStorageClass: self.nvme_storage_class,
  nginxIngressClass: 'nginx',

  defaultAppConfig: utils.appConfig + {
    configVolStorageClass: weebcluster.defaultStorageClass,
    primaryDomains: homelab.allDomains,
    ingressClass: weebcluster.nginxIngressClass,
  },

  // Inline Tanka environment
  newTankaEnv(envName, namespace, data):: 
    utils.newTankaEnv('https://aomine.' + homelab.defaultDomain + ':6443', envName, namespace, data),

  newStandardApp(appConfig)::
    utils.newStandardApp(weebcluster.defaultAppConfig + appConfig),

  // Creates several resources needed for a PV/PVC pointed at the one of the NFS shares (with optional subpath)
  // Appends the server domain name to the PV/PVC names to prevent collisions when switching between servers since
  //  existing PV/PVC can't be updated to new server.
  newNfsVolume(appName, shareName, subPath=''):: {
    local subPathName = '-' + shareName + std.strReplace(subPath, '/', '-'),
    local primaryNfs = homelab.nfs.currentPrimary,
    local rootName = appName + '-nfs-' + primaryNfs.server,
    nfsPV: utils.newNfsPV(
      name=rootName + subPathName + '-pv',
      server=primaryNfs.server,
      path=primaryNfs.shares[shareName] + subPath,
      size=primaryNfs.totalSize),
    nfsPVC: utils.newNfsPVCFromPV(rootName + subPathName, self.nfsPV),
    volume:: utils.newVolumeFromPVC('nfs' + subPathName, self.nfsPVC),
    volumeMount:: kube.core.v1.volumeMount.new(self.volume.name, '/data'),
  },

  // The Servarr family of apps require that NFS be mounted with 'nolock' set. 
  newNfsVolumeNolock(appName, shareName, subPath='')::
    self.newNfsVolume(appName, shareName, subPath) + {
      nfsPV+: kube.core.v1.persistentVolume.spec.withMountOptions(['nolock'])
    },
}
