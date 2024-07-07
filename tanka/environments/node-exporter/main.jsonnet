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

  filesystemMountPointsExclude::
    // Stolen from kube-prometheus' node-exporter setup
    '^/(dev|proc|sys|run/k3s/containerd/.+|var/lib/docker/.+|var/lib/kubelet/pods/.+)($|/)',
  netDevExclude:: '^(veth.+|cali.+)$', // I use Calico

  // Initial node-exporter resources. Needed separately for follow-up modification.
  node_exporter_base::
    node_exporter.new(weebcluster.images.node_exporter.image)
    + node_exporter.mountRoot()
    + node_exporter.withExcludedMountPoints(self.filesystemMountPointsExclude),

  // Grafana's node-exporter library doesn't provide a way to replace the netdev exclude argument...
  // Extract all the args except that one, then append the new arg and replace the args of the container
  local neContainerArgs = std.filter(
    function(arg) !std.native('regexMatch')('netdev\\.device-exclude', arg), // This is a Tanka-provided function
    self.node_exporter_base.container.args
  ),
  local netDevExcludeArg = ['--collector.netdev.device-exclude=%s' % self.netDevExclude],

  // Final node-exporter resourses
  node_exporter: self.node_exporter_base 
    + { container+:: k.core.v1.container.withArgs(neContainerArgs + netDevExcludeArg) },

  local prometheus_config = scrapeConfigGen(namespace),
  scrapeConfig:
    scrapeConfig.new('node-exporter-scrape-config')
    + scrapeConfig.spec.withKubernetesSDConfigs(prometheus_config.kubernetesSDConfigs)
    + scrapeConfig.spec.withRelabelings(prometheus_config.relabelings)
};

weebcluster.newTankaEnv(envName, namespace, nodeExporterEnv)