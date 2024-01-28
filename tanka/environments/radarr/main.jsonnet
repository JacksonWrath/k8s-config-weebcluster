local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';
local kube = import '1.27/main.libsonnet';

// API object aliases
local container = kube.core.v1.container;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'radarr';
local namespace = 'radarr';

local radarrEnvironment = {
  local appName = 'radarr',
  local image = weebcluster.images.radarr.image,
  local ingressSubdomain = 'nozomi',
  local configVolSize = '10Gi',
  local httpPortNumber = 7878,

  namespace: kube.core.v1.namespace.new(namespace),

  mediaVol: weebcluster.newYoRHaNfsVolumeNolock(appName, '/media'),

  radarrApp: weebcluster.newStandardApp(appName, image, configVolSize, httpPortNumber, ingressSubdomain) {
    local envMap = {PUID: '1000', PGID: '1000'},
    container+::
      container.withEnvMap(envMap) +
      container.withVolumeMountsMixin([radarrEnvironment.mediaVol.volumeMount]),
    deployment+:
      podTemplateSpec.withVolumesMixin([radarrEnvironment.mediaVol.volume]),
  }
};

weebcluster.newTankaEnv(envName, namespace, radarrEnvironment)