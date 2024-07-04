local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';

local envName = 'kube-prometheus';
local namespace = 'prometheus';
local prometheusSubdomain = 'prometheus';
local alertmanagerSubdomain = 'alertmanager';

local kp =
  (import 'kube-prometheus/main.libsonnet') +
  (import 'kube-prometheus/addons/all-namespaces.libsonnet') +
  (import 'kube-prometheus/addons/networkpolicies-disabled.libsonnet') +
  // (import 'kube-prometheus/addons/anti-affinity.libsonnet') +
  // (import 'kube-prometheus/addons/managed-cluster.libsonnet') +
  // (import 'kube-prometheus/addons/node-ports.libsonnet') +
  // (import 'kube-prometheus/addons/static-etcd.libsonnet') +
  // (import 'kube-prometheus/addons/custom-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/external-metrics.libsonnet') +
  // (import 'kube-prometheus/addons/pyrra.libsonnet') +
  {
    values+:: {
      common+: {
        namespace: namespace,
      },
      prometheus+: {
        namespaces: [],
        prometheus+: {
          spec+: {
            externalUrl: 'https://' + prometheusSubdomain + '.' + homelab.defaultDomain,
          },
        },
      },
    },
  };

local getServicePortObj(component, portName) =
  local kpServicePortObjList = std.filter((function(port) port.name == portName), kp[component].service.spec.ports);
  local portListLength = std.length(kpServicePortObjList);
  if portListLength != 1 
  then error 'expected only 1 servicePort object on component "' + component + '"; got ' + portListLength
  else kpServicePortObjList[0];

local environmentData = 
  { 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
  {
    ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
    for name in std.filter(
      (function(name) name != 'serviceMonitor' && name != 'prometheusRule'), 
      std.objectFields(kp.prometheusOperator),
    )
  } +
  // { 'setup/pyrra-slo-CustomResourceDefinition': kp.pyrra.crd } +
  // serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
  // (This shouldn't matter for Tanka, which detects and creates CRDs first)
  { 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
  { 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
  { 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
  { ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
  { ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
  // { ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
  // { ['pyrra-' + name]: kp.pyrra[name] for name in std.objectFields(kp.pyrra) if name != 'crd' } +
  { ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
  { ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
  { ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
  { ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
  { ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
  {
    prometheusIngress: weebcluster.newStandardIngress(
      kp.prometheus.service.metadata.name,
      prometheusSubdomain, 
      kp.prometheus.service, 
      getServicePortObj('prometheus', 'web'),
    ),
    alertmanagerIngress: weebcluster.newStandardIngress(
      kp.alertmanager.service.metadata.name,
      alertmanagerSubdomain,
      kp.alertmanager.service,
      getServicePortObj('alertmanager', 'web'),
    ),
  };

weebcluster.newTankaEnv(envName, namespace, environmentData) + 
{
  spec+: {
    // This is needed because the "last-applied-configuration" from client-side apply ends up being too long
    applyStrategy: 'server',
    // This allows running 'tk prune' to clean up removed resources.
    injectLabels: true,
  },
}