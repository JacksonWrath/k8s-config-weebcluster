local weebcluster = import 'weebcluster.libsonnet';
local kube = import 'k.libsonnet';
local pvc = kube.core.v1.persistentVolumeClaim;

local envName = 'tautulli';
local namespace = 'plex';

local appConfig = {
  appName: 'tautulli',
  image: weebcluster.images.tautulli.image,
  subdomain: 'morgiana',
  configVolSize: '1Gi',
  httpPortNumber: 8181,
};

local tautulliEnvironment = {
  tautulliApp: weebcluster.newStandardApp(appConfig) {
    configVolume+: {
      configPVC+: pvc.metadata.withLabelsMixin({
          'backup.restic.io/enabled': 'true',
        }),
    },
  },
};

weebcluster.newTankaEnv(envName, namespace, tautulliEnvironment)