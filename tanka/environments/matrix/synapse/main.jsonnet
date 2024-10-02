local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local utils = import 'utils.libsonnet';
local k = import 'k.libsonnet';

// k8s resource aliases
local container = k.core.v1.container;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;
local podTemplateSpec = k.apps.v1.deployment.spec.template.spec;

// Environment config
local envName = 'matrixSynapse';
local namespace = 'matrix-synapse';

local appName = 'matrix-synapse';
local image = weebcluster.images.matrix_synapse.image;
local configVolSize = '10Gi';
local httpPortNumber = 8080;
local ingressSubdomain = '3d1b';
local additionalLabels = {};

// Environment
local matrixSynapseEnv = {
  namespace: k.core.v1.namespace.new(namespace),

  local configFile = std.parseYaml(importstr 'config.yaml') + {email+: private.synapse},
  configConfigMap: k.core.v1.configMap.new(
    'config-file',
    {'homeserver.yaml': std.manifestYamlDoc(configFile, indent_array_in_object=true, quote_keys=false)}
  ),

  local loggingConfigFile = importstr 'logging-config.yaml',
  loggingConfigConfigMap: k.core.v1.configMap.new('logging-config', {'3d1b.log.config': loggingConfigFile}),

  local additionalVolumes = [
    volume.fromConfigMap('config-file', 'config-file', [{key: 'homeserver.yaml', path: 'homeserver.yaml'}]),
    volume.fromConfigMap('logging-config', 'logging-config', [{key: '3d1b.log.config', path: '3d1b.log.config'}]),
  ],

  synapseApp: weebcluster.newStandardApp(appName, image, configVolSize, httpPortNumber, ingressSubdomain, additionalLabels) +
  {
    local configFileVolumeMount = volumeMount.new('config-file', '/config/homeserver.yaml')
      + volumeMount.withSubPath('homeserver.yaml'),
    local loggingConfigVolumeMount = volumeMount.new('logging-config', '/config/3d1b.log.config')
      + volumeMount.withSubPath('3d1b.log.config'),
    container+:: container.withVolumeMountsMixin([configFileVolumeMount, loggingConfigVolumeMount])
      + container.withEnvMap({
        SYNAPSE_CONFIG_DIR: '/config',
      }),

    deployment+: podTemplateSpec.withVolumesMixin(additionalVolumes)
      + podTemplateSpec.securityContext.withFsGroup(991),

    ingress+: k.networking.v1.ingress.metadata.withAnnotationsMixin(utils.nginxIngressAllowAll),
  },
};

weebcluster.newTankaEnv(envName, namespace, matrixSynapseEnv)