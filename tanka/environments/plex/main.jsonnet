local kube = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local utils = import 'utils.libsonnet';

// API object aliases
local container = kube.core.v1.container;
local volumeMount = kube.core.v1.volumeMount;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'plex';
local namespace = 'plex';

local appConfig = {
  appName: 'plex',
  image: weebcluster.images.plex.image,
  subdomain: 'satsuki',
  configVolSize: '100Gi',
  httpPortNumber: 32400,
};

local plexEnvironment = {
  local primaryNfs = homelab.nfs.currentPrimary,

  // Transcoding volume
  transcodingPvc: utils.newStandardPVC('plex-transcode', '20Gi', weebcluster.defaultStorageClass),

  // Promtail config ConfigMap
  local promtailConfig = std.manifestYamlDoc(import 'promtail-config.jsonnet', quote_keys=false),
  promtailConfigMap: kube.core.v1.configMap.new('promtail-plex', {'promtail.yaml': promtailConfig}),

  // Additional volumes on deployment
  local additionalVolumes = [
    utils.newVolumeFromPVC('plex-transcode', self.transcodingPvc),
    utils.newNfsVolume('plex-media', primaryNfs.server, primaryNfs.shares.media + '/plex'),
    kube.core.v1.volume.fromConfigMap('promtail-config', self.promtailConfigMap.metadata.name),
  ],

  // Promtail container
  local promtailContainer = container.new('promtail', weebcluster.images.promtail.image) +
    container.withArgs(['-config.file=/etc/promtail/promtail.yaml']) +
    container.withVolumeMounts([
      volumeMount.new('promtail-config', '/etc/promtail'),
      volumeMount.new('config', '/config/plex-volume', true),
    ]),

  plexApp: weebcluster.newStandardApp(appConfig) {
    container+:: container.withVolumeMountsMixin([
      volumeMount.new('plex-transcode', '/transcode'),
      volumeMount.new('plex-media', '/media/plex'),
    ]),
    deployment+: podTemplateSpec.withContainersMixin([promtailContainer]) +
      podTemplateSpec.withVolumesMixin(additionalVolumes),
    ingress+: kube.networking.v1.ingress.metadata.withAnnotationsMixin(utils.nginxIngressAllowAll),
  },
};

weebcluster.newTankaEnv(envName, namespace, plexEnvironment)