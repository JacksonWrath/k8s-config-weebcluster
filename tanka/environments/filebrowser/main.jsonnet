local kube = import 'k.libsonnet';
local utils = import 'utils.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';

// API object aliases
local container = kube.core.v1.container;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'filebrowser';
local namespace = 'filebrowser';

local appConfig = {
  appName: 'filebrowser',
  image: weebcluster.images.filebrowser.image,
  subdomain: 'asuna-fb',
  configVolSize: '1Gi',
  httpPortNumber: 80,
};

local filebrowserEnvironment = {
  namespace: kube.core.v1.namespace.new(namespace),

  // NFS Volume for YoRHa
  yorhaVol: weebcluster.newNfsVolume(appConfig.appName, 'YoRHa', ''),

  // Application
  filebrowserApp: weebcluster.newStandardApp(appConfig) {
    local envMap = {
      FB_DATABASE: '/config/filebrowser.db',
      FB_ROOT: '/data',
    },

    container+::
      container.withEnvMap(envMap) +
      container.withVolumeMountsMixin([
        filebrowserEnvironment.yorhaVol.volumeMount {
          mountPath: '/data/YoRHa',
          readOnly: false,
        },
      ]),

    deployment+:
      podTemplateSpec.withVolumesMixin([filebrowserEnvironment.yorhaVol.volume]) +
      podTemplateSpec.securityContext.withRunAsUser(1000) +
      podTemplateSpec.securityContext.withRunAsGroup(1000) +
      podTemplateSpec.securityContext.withFsGroup(1000),

    ingress+:
      kube.networking.v1.ingress.metadata.withAnnotationsMixin({
        'nginx.ingress.kubernetes.io/proxy-body-size': '25m',
        'nginx.ingress.kubernetes.io/proxy-buffering': 'off',
        'nginx.ingress.kubernetes.io/proxy-request-buffering': 'off',
      }),
  },
};

weebcluster.newTankaEnv(envName, namespace, filebrowserEnvironment)
