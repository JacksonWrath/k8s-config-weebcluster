local kube = import '1.27/main.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local utils = import 'utils.libsonnet';

// API object aliases
local container = kube.core.v1.container;
local volumeMount = kube.core.v1.volumeMount;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'plex';
local namespace = 'plex';

local plexEnvironment = {
  local appName = 'plex',
  local plexImage = weebcluster.images.plex.image,
  local promtailImage = weebcluster.images.promtail.image,
  local ingressSubdomain = 'satsuki',
  local configVolSize = '100Gi',
  local httpPortNumber = 32400,

  // Transcoding volume
  transcodingPvc: weebcluster.newStandardPVC('plex-transcode', '20Gi'),

  // Promtail config ConfigMap
  local promtailConfig = std.manifestYamlDoc(import 'promtail-config.jsonnet', quote_keys=false),
  promtailConfigMap: kube.core.v1.configMap.new('promtail-plex', {'promtail.yaml': promtailConfig}),

  // Additional volumes on deployment
  local additionalVolumes = [
    utils.newVolumeFromPVC('plex-transcode', self.transcodingPvc),
    utils.newNfsVolume('plex-media', homelab.nfs.asuna.server, homelab.nfs.asuna.shares.YoRHa + '/media/plex'),
    kube.core.v1.volume.fromConfigMap('promtail-config', self.promtailConfigMap.metadata.name),
  ],

  // Promtail container
  local promtailContainer = container.new('promtail', promtailImage) +
    container.withArgs(['-config.file=/etc/promtail/promtail.yaml']) +
    container.withVolumeMounts([
      volumeMount.new('promtail-config', '/etc/promtail'),
      volumeMount.new('config', '/config/plex-volume', true),
    ]),

  plexApp: weebcluster.newStandardApp(appName, plexImage, configVolSize, httpPortNumber, ingressSubdomain) {
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