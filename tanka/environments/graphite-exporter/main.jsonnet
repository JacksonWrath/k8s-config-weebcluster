local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local prometheus = import 'prometheus/main.libsonnet';
local k = import 'k.libsonnet';

local envName = 'graphiteExporter';
local namespace = 'graphite-exporter';
local appName = 'graphite-exporter';

local image = weebcluster.images.graphite_exporter.image;

local labels = {
  app: appName,
};

local graphiteExporterEnv = {
  namespace: k.core.v1.namespace.new(namespace),

  local configFileName = 'graphite-mapping.conf',
  graphiteConfigMapData:: { [configFileName]: importstr 'truenas-graphite-to-prometheus/graphite_mapping.conf' },
  graphiteMappingConfigMap: k.core.v1.configMap.new(configFileName, self.graphiteConfigMapData),

  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,
  containerMetricsPort:: containerPort.newNamed(9108, 'metrics'),
  containerTcpPort:: containerPort.newNamed(9109, 'tcp'),
  containerUdpPort:: containerPort.newNamedUDP(9109, 'udp'),
  graphiteConfigVolume:: k.core.v1.volume.fromConfigMap('graphite-mapping', configFileName),
  local graphiteConfigMountPath = '/config/',
  graphiteConfigVolumeMount:: k.core.v1.volumeMount.new(self.graphiteConfigVolume.name, graphiteConfigMountPath, true),
  container:: container.new(appName, image)
    + container.withVolumeMounts([self.graphiteConfigVolumeMount])
    + container.withArgs(['--graphite.mapping-config='+graphiteConfigMountPath+configFileName])
    + container.withPorts([
      self.containerTcpPort,
      self.containerUdpPort,
      self.containerMetricsPort,
    ]),

  deployment: utils.newSinglePodDeployment('graphite-exporter', self.container, labels)
    + k.apps.v1.deployment.spec.template.spec.withVolumes(self.graphiteConfigVolume),

  local service = k.core.v1.service,
  local servicePort = k.core.v1.servicePort,
  metricsServicePort:: servicePort.newNamed('metrics', 9108, self.containerMetricsPort.name),
  tcpServicePort:: servicePort.newNamed('tcp', 9109, self.containerTcpPort.name),
  udpServicePort:: servicePort.newNamed('udp', 9109, self.containerUdpPort.name) + servicePort.withProtocol('UDP'),
  metricsService: service.new('metrics', labels, [self.metricsServicePort])
    + service.metadata.withLabels(labels),
  ingestService: service.new('ingest', labels, [
    self.tcpServicePort,
    self.udpServicePort,
  ]),

  local serviceMonitor = prometheus.monitoring.v1.serviceMonitor,
  serviceMonitor: serviceMonitor.new('graphite-exporter')
   + serviceMonitor.spec.selector.withMatchLabels(labels)
   + serviceMonitor.spec.withEndpoints({port: 'metrics', honorLabels: true}),
};

weebcluster.newTankaEnv(envName, namespace, graphiteExporterEnv) + {
  spec+: {
    applyStrategy: 'server',
  },
}