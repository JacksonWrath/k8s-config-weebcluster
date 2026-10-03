local kube = import 'k.libsonnet';
local homelab = import 'homelab.libsonnet';
local utils = import 'utils.libsonnet';
local imageLib = import 'images.libsonnet';

{
  makeCluster(clusterSpec):: clusterSpec {
    local cluster = self,
    images: imageLib.images,
    
    defaultAppConfig: utils.appConfig + {
      configVolStorageClass: cluster.defaultStorageClass,
      primaryDomains: homelab.allDomains,
      ingressClass: cluster.nginxIngressClass,
      tlsEnabled: if std.objectHas(cluster, 'tlsEnabled') then cluster.tlsEnabled else utils.appConfig.tlsEnabled,
    },

    newTankaEnv(envName, namespace, data)::
      utils.newTankaEnv(envName, cluster, namespace, data),

    newStandardApp(appConfig)::
      utils.newStandardApp(cluster.defaultAppConfig + appConfig),

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

    newNfsVolumeNolock(appName, shareName, subPath='')::
      cluster.newNfsVolume(appName, shareName, subPath) + {
        nfsPV+: kube.core.v1.persistentVolume.spec.withMountOptions(['nolock'])
      },
  }
}
