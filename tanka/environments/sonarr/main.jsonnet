local weebcluster = import 'weebcluster.libsonnet';
local kube = import 'k.libsonnet';

// API object aliases
local container = kube.core.v1.container;
local pvc = kube.core.v1.persistentVolumeClaim;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'sonarr';
local namespace = 'sonarr';

local appConfig = {
  appName: 'sonarr',
  image: weebcluster.images.sonarr.image,
  subdomain: 'nozaki',
  configVolSize: '10Gi',
  httpPortNumber: 8989,
};

local sonarrEnvironment = {
  namespace: kube.core.v1.namespace.new(namespace),

  mediaVol: weebcluster.newNfsVolumeNolock(appConfig.appName, 'media'),

  sonarrApp: weebcluster.newStandardApp(appConfig) {
    configVolume+: {
      configPVC+: pvc.metadata.withLabelsMixin({
          'backup.restic.io/enabled': 'true',
        }),
    },
    local envMap = {PUID: '1000', PGID: '1000'},
    container+::
      container.withEnvMap(envMap) +
      container.withVolumeMountsMixin([sonarrEnvironment.mediaVol.volumeMount]),
    deployment+:
      podTemplateSpec.withVolumesMixin([sonarrEnvironment.mediaVol.volume]),
  }
};

weebcluster.newTankaEnv(envName, namespace, sonarrEnvironment)