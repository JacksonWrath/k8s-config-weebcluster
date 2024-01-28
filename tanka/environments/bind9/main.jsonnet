local kube = import '1.27/main.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local utils = import 'utils.libsonnet';

// API object aliases
local container = kube.core.v1.container;
local configMap = kube.core.v1.configMap;
local volume = kube.core.v1.volume;
local volumeMount = kube.core.v1.volumeMount;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'bind9';
local namespace = 'bind-dns';

local bindEnvironment = {
  local appName = 'bind9',
  local image = 'ubuntu/bind9:latest', // Ubuntu constantly pushes to all tags, rather than freezing them at a version.
  local dnsIp = '10.2.69.10',

  local labels = {
    app: appName,
  },

  namespace: kube.core.v1.namespace.new(namespace),

  namedConfigMap: configMap.new('named-conf', import 'named-conf.jsonnet'),
  zonesConfigMap: configMap.new('zones-conf', import 'zones.jsonnet'),
  zonesStaticConfigMap: configMap.new('zones-static-conf', import 'zones-static.jsonnet'),

  local bind9Container = utils.newDnsContainer(appName, image) + 
    container.withVolumeMounts([
      volumeMount.new('named-vol', '/etc/bind'),
      volumeMount.new('zones-vol', '/var/bind/zones'),
      volumeMount.new('zones-static-vol', '/var/bind/zones-static'),
    ]),

  bind9Deployment: utils.newSinglePodDeployment(appName, [bind9Container], labels) +
    podTemplateSpec.withVolumes([
      volume.fromConfigMap('named-vol', self.namedConfigMap.metadata.name),
      volume.fromConfigMap('zones-vol', self.zonesConfigMap.metadata.name),
      volume.fromConfigMap('zones-static-vol', self.zonesStaticConfigMap.metadata.name),
    ]),

  bind9Service: utils.newDnsService(appName, self.bind9Deployment.spec.selector.matchLabels, dnsIp),
};

weebcluster.newTankaEnv(envName, namespace, bindEnvironment)
