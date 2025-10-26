local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local utils = import 'utils.libsonnet';
local k = import 'k.libsonnet';

local envName = 'gallery-dl';
local namespace = 'gallery-dl';

local appConfig = {
  appName: 'gallery-dl',
  image: weebcluster.images.gallery_dl.image,
  configVolSize: '10Gi',
};

local gallerydlEnv = {
  local primaryNfs = homelab.nfs.currentPrimary,

  local gallerydlConfig = std.manifestJson(import 'gallery-dl-config.jsonnet'),
  configMap: k.core.v1.configMap.new('gallery-dl-config', {'config.json': gallerydlConfig}),

  local additionalVolumes = [
    utils.newNfsVolume('weeb', primaryNfs.server, primaryNfs.shares.YoRHa + '/weeb'),
    k.core.v1.volume.fromConfigMap('gallery-dl-config', self.configMap.metadata.name),
  ],
};

weebcluster.newTankaEnv(envName, namespace, gallerydlEnv)