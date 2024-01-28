local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';
local kube = import '1.27/main.libsonnet';

// API object aliases
local container = kube.core.v1.container;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'sonarr';
local namespace = 'sonarr';

local sonarrEnvironment = {
  local appName = 'sonarr',
  local image = weebcluster.images.sonarr.image,
  local ingressSubdomain = 'nozaki',
  local configVolSize = '10Gi',
  local httpPortNumber = 8989,

  namespace: kube.core.v1.namespace.new(namespace),

  mediaVol: weebcluster.newYoRHaNfsVolumeNolock(appName, '/media'),

  sonarrApp: weebcluster.newStandardApp(appName, image, configVolSize, httpPortNumber, ingressSubdomain) {
    local envMap = {PUID: '1000', PGID: '1000'},
    container+::
      container.withEnvMap(envMap) +
      container.withVolumeMountsMixin([sonarrEnvironment.mediaVol.volumeMount]),
    deployment+:
      podTemplateSpec.withVolumesMixin([sonarrEnvironment.mediaVol.volume]),
  }
};

weebcluster.newTankaEnv(envName, namespace, sonarrEnvironment)