local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local helm = import 'k3s-helm.libsonnet';
local prometheusLib = import 'prometheus/main.libsonnet';

local envName = 'rook-ceph';
local namespace = 'rook-ceph';

local certManagerEnv = {
  local chartConfig = {
    chartId: 'rook-ceph',
    targetNamespace: namespace,
  },

  namespace: k.core.v1.namespace.new(namespace),

  helmChart: helm.newHelmChart(chartConfig),
  // This helm chart is just deploying the operator. The actual cluster and other resources are still just plain YAML 
  // manifests, in the "manifests" folder alongside this file.

  // ServiceMonitors for Prometheus. Rook sets up these services by default.
  local serviceMonitor = prometheusLib.monitoring.v1.serviceMonitor,
  mgrServiceMonitor: serviceMonitor.new('ceph-mgr-servicemonitor')
    + serviceMonitor.spec.selector.withMatchLabels({app: 'rook-ceph-mgr', rook_cluster: 'rook-ceph'})
    + serviceMonitor.spec.withEndpoints(
        serviceMonitor.spec.endpoints.withPort('http-metrics')
          + serviceMonitor.spec.endpoints.withHonorLabels(true),
      ),

  exporterServiceMonitor: serviceMonitor.new('ceph-exporter-servicemonitor')
    + serviceMonitor.spec.selector.withMatchLabels({app: 'rook-ceph-exporter', rook_cluster: 'rook-ceph'})
    + serviceMonitor.spec.withEndpoints(serviceMonitor.spec.endpoints.withPort('ceph-exporter-http-metrics')),
};

weebcluster.newTankaEnv(envName, namespace, certManagerEnv)