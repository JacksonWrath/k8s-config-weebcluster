local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local helm = import 'k3s-helm.libsonnet';
local prometheusLib = import 'prometheus/main.libsonnet';

local envName = 'rook-ceph';
local namespace = 'rook-ceph';

local appConfig = weebcluster.defaultAppConfig + {
  cephImage: 'quay.io/ceph/ceph:v19.2.0',
};

local dashboardIngressConfig = appConfig + {
  appName: 'dashboard',
  subdomain: 'ceph',
};

local rgwIngressConfig = appConfig + {
  appName: 'rgw',
  subdomain: 'mako',
};

local rookCephEnv = {
  local chartConfig = {
    chartId: 'rook-ceph',
    targetNamespace: namespace,
  },

  namespace: k.core.v1.namespace.new(namespace),

  rookOperatorHelmChart: helm.newHelmChart(chartConfig),

  cephCluster: std.parseYaml(importstr 'manifests/cephcluster.yaml') +
    {
      spec+: {
        cephVersion: {
          image: appConfig.cephImage,
        },
      },
    },

  // Ingresses
  // The Ingress utility functions expect the service objects to be passed, just to get the names
  // Since the operator creates those, minimal placeholder objects are passed
  dashboardIngress: utils.newStandardIngress(
    k.core.v1.service.metadata.withName('rook-ceph-mgr-dashboard'), 
    k.core.v1.servicePort.withName('http-dashboard'), 
    dashboardIngressConfig,
  ),

  rgwIngress: utils.newStandardHttpIngress(
    k.core.v1.service.metadata.withName('rook-ceph-rgw-objectify-me-daddy'),
    rgwIngressConfig,
  ),

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

weebcluster.newTankaEnv(envName, namespace, rookCephEnv)