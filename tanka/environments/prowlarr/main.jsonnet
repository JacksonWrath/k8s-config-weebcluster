local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';
local kube = import 'k.libsonnet';

// API object aliases
local container = kube.core.v1.container;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'prowlarr';
local namespace = 'prowlarr';

local prowlarrEnvironment = {
  local appName = 'prowlarr',
  local image = weebcluster.images.prowlarr.image,
  local ingressSubdomain = 'riko',
  local configVolSize = '1Gi',
  local httpPortNumber = 9696,

  namespace: kube.core.v1.namespace.new(namespace),

  prowlarrApp: weebcluster.newStandardApp(appName, image, configVolSize, httpPortNumber, ingressSubdomain) {
    local envMap = {PUID: '1000', PGID: '1000'},
    container+::
      container.withEnvMap(envMap),
  }
};

weebcluster.newTankaEnv(envName, namespace, prowlarrEnvironment)