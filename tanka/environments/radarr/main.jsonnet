local weebcluster = import 'weebcluster.libsonnet';
local kube = import 'k.libsonnet';

// API object aliases
local container = kube.core.v1.container;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'radarr';
local namespace = 'radarr';

local appConfig = {
  appName: 'radarr',
  image: weebcluster.images.radarr.image,
  subdomain: 'nozomi',
  configVolSize: '10Gi',
  httpPortNumber: 7878,
};

local radarrEnvironment = {
  namespace: kube.core.v1.namespace.new(namespace),

  mediaVol: weebcluster.newNfsVolumeNolock(appConfig.appName, 'media'),

  radarrApp: weebcluster.newStandardApp(appConfig) {
    local envMap = {PUID: '1000', PGID: '1000'},
    container+::
      container.withEnvMap(envMap) +
      container.withVolumeMountsMixin([radarrEnvironment.mediaVol.volumeMount]),
    deployment+:
      podTemplateSpec.withVolumesMixin([radarrEnvironment.mediaVol.volume]),
  }
};

weebcluster.newTankaEnv(envName, namespace, radarrEnvironment)