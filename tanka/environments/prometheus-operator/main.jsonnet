local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local prometheusLib = import 'prometheus/main.libsonnet';
local prometheusOperator = import 'prometheus-operator/prometheus-operator/prometheus-operator.libsonnet';
// lol department of redundancy department

local envName = 'prometheus-operator';
local namespace = 'prometheus-operator';

local poGithubUrl = 'https://github.com/prometheus-operator/prometheus-operator.git';
local poLibVersion = std.filter(
  function(dep) dep.source.git.remote == poGithubUrl, 
  (import '../jsonnetfile.json').dependencies
)[0].version;

local config = {
  namespace: namespace,
  version: std.strReplace(poLibVersion, 'v', ''),
  image: 'quay.io/prometheus-operator/prometheus-operator:v' + self.version,
  configReloaderImage: 'quay.io/prometheus-operator/prometheus-config-reloader:v' + self.version,
};

local poEnv = prometheusOperator(config) {
  namespace: k.core.v1.namespace.new(namespace),

  // This ServiceMonitor lives here because the Prometheus Operator is what's responsible for creating the "kubelet"
  // service it monitors (via --kubelet-service flag). The jsonnet lib they provide creates it at "kubelet/kube-system".
  //
  // Note that the http port is disabled by default these days. I've re-enabled it (--read-only-port kubelet flag).
  // The https port can work too, but Prometheus would need extra config to trust the self-signed cert and use the
  // bearer token. I can't be bothered to set that up right now.
  local serviceMonitor = prometheusLib.monitoring.v1.serviceMonitor,
  kubeletServiceMonitor: serviceMonitor.new('kubelet-servicemonitor')
    + serviceMonitor.spec.selector.withMatchLabels({
      'app.kubernetes.io/managed-by': 'prometheus-operator',
      'app.kubernetes.io/name': 'kubelet',
    })
    + serviceMonitor.spec.namespaceSelector.withMatchNames('kube-system')
    + serviceMonitor.spec.withEndpoints([
      serviceMonitor.spec.endpoints.withPort('http-metrics')
        + serviceMonitor.spec.endpoints.withHonorLabels(true),
      serviceMonitor.spec.endpoints.withPort('http-metrics')
        + serviceMonitor.spec.endpoints.withPath('/metrics/cadvisor')
        + serviceMonitor.spec.endpoints.withHonorLabels(true),
    ]),
};

weebcluster.newTankaEnv(envName, namespace, poEnv)