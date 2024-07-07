local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local k = import 'k.libsonnet';

local node_exporter = import 'node-exporter/main.libsonnet';
local prometheusLib = import 'prometheus/main.libsonnet';
local scrapeConfig = prometheusLib.monitoring.v1alpha1.scrapeConfig;
local scrapeConfigGen = import 'scrape_config.libsonnet';


local envName = 'nodeExporter';
local namespace = 'node-exporter';

local nodeExporterEnv = {
  namespace: k.core.v1.namespace.new(namespace),

  node_exporter:
    node_exporter.new(weebcluster.images.node_exporter.image)
    + node_exporter.mountRoot(),

  local prometheus_config = scrapeConfigGen(namespace),

  scrapeConfig:
    scrapeConfig.new('node-exporter-scrape-config')
    + scrapeConfig.spec.withKubernetesSDConfigs(prometheus_config.kubernetesSDConfigs)
    + scrapeConfig.spec.withRelabelings(prometheus_config.relabelings)
};

weebcluster.newTankaEnv(envName, namespace, nodeExporterEnv)