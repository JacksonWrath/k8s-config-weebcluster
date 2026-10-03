local weebcluster = import 'weebcluster.libsonnet';
local kube = import 'k.libsonnet';

// API object aliases
local container = kube.core.v1.container;
local pvc = kube.core.v1.persistentVolumeClaim;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'prowlarr';
local namespace = 'prowlarr';

local appConfig = {
  appName: 'prowlarr',
  image: weebcluster.images.prowlarr.image,
  subdomain: 'riko',
  configVolSize: '1Gi',
  httpPortNumber: 9696,
};

local prowlarrEnvironment = {
  namespace: kube.core.v1.namespace.new(namespace),

  prowlarrApp: weebcluster.newStandardApp(appConfig) {
    configVolume+: {
      configPVC+: pvc.metadata.withLabelsMixin({
          'backup.restic.io/enabled': 'true',
        }),
    },
    local envMap = {PUID: '1000', PGID: '1000'},
    container+::
      container.withEnvMap(envMap),
  }
};

weebcluster.newTankaEnv(envName, namespace, prowlarrEnvironment)