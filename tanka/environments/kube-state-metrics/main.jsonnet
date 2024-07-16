local weebcluster = import 'weebcluster.libsonnet';
local k = import 'k.libsonnet';
local ksm = import 'ksm/kube-state-metrics/kube-state-metrics.libsonnet';
local prometheus = import 'prometheus/main.libsonnet';

local envName = 'kubeStateMetrics';
local appName = 'kube-state-metrics';
local namespace = 'kube-state-metrics';

local kubeStateMetricsEnv = ksm {
  namespaceResource: k.core.v1.namespace.new(namespace),

  local serviceMonitor = prometheus.monitoring.v1.serviceMonitor,
  serviceMonitorEndpoint:: serviceMonitor.spec.endpoints.withPort('http-metrics')
    + serviceMonitor.spec.endpoints.withHonorLabels(true),
  serviceMonitor: serviceMonitor.new('ksm-servicemonitor')
    + serviceMonitor.spec.selector.withMatchLabels({
      'app.kubernetes.io/name': 'kube-state-metrics',
    })
    + serviceMonitor.spec.withEndpoints(self.serviceMonitorEndpoint),

  name:: appName,
  namespace:: namespace,
  version:: weebcluster.images.kube_state_metrics.followTag,
  image:: weebcluster.images.kube_state_metrics.image,
};

weebcluster.newTankaEnv(envName, namespace, kubeStateMetricsEnv)