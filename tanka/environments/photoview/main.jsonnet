local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local kube = import 'k.libsonnet';

// API object aliases
local container = kube.core.v1.container;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'photoview';
local namespace = 'photoview';

local appConfig = {
  appName: 'photoview',
  image: weebcluster.images.photoview.image,
  subdomain: 'photoview',
  configVolSize: '20Gi',
  httpPortNumber: 80,
};

local photoviewEnvironment = {
  namespace: kube.core.v1.namespace.new(namespace),

  // NFS Volume for Photos
  photosVol: weebcluster.newNfsVolume(appConfig.appName, 'YoRHa', '/weeb'),

  // Application
  photoviewApp: weebcluster.newStandardApp(appConfig) {
    local envMap = {
      PHOTOVIEW_DATABASE_DRIVER: 'sqlite',
      PHOTOVIEW_SQLITE_PATH: '/config/photoview.db',
      PHOTOVIEW_MEDIA_CACHE: '/config/cache',
      PHOTOVIEW_LISTEN_IP: '0.0.0.0',
      PHOTOVIEW_DEVELOPMENT_MODE: 'true',
    },

    container+::
      container.withEnvMap(envMap) +
      container.withVolumeMountsMixin([
        // Override the default mount from newNfsVolume to be readOnly and at /photos
        photoviewEnvironment.photosVol.volumeMount {
            mountPath: '/photos',
            readOnly: true,
        },
      ]),

    deployment+:
      podTemplateSpec.withVolumesMixin([photoviewEnvironment.photosVol.volume]) +
      podTemplateSpec.securityContext.withRunAsUser(1000) +
      podTemplateSpec.securityContext.withRunAsGroup(1000) +
      podTemplateSpec.securityContext.withFsGroup(1000),
  },
};

weebcluster.newTankaEnv(envName, namespace, photoviewEnvironment)
