local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';
local k = import 'k.libsonnet';

// prometheus resources
local prometheusLib = import 'prometheus/main.libsonnet';
local prometheus = prometheusLib.monitoring.v1.prometheus;

// k8s resources
local rbac = k.rbac.v1;
local serviceAccount = k.core.v1.serviceAccount;

local envName = 'prometheus';
local namespace = 'prometheus';

local clusterName = 'prometheus-1';

local appConfig = weebcluster.defaultAppConfig + {
  appName: clusterName,
  subdomain: 'prometheus',
};

local prometheusEnv = {
  namespace: k.core.v1.namespace.new(namespace),

  serviceAccount: serviceAccount.new(clusterName)
    + serviceAccount.metadata.withNamespace(namespace),
  clusterRoleRules:: [
    rbac.policyRule.withApiGroups([''])
      + rbac.policyRule.withResources(['nodes', 'nodes/metrics', 'services', 'endpoints', 'pods'])
      + rbac.policyRule.withVerbs(['get', 'list', 'watch']),

    rbac.policyRule.withApiGroups([''])
      + rbac.policyRule.withResources(['configmaps'])
      + rbac.policyRule.withVerbs(['get']),

    rbac.policyRule.withApiGroups(['networking.k8s.io'])
      + rbac.policyRule.withResources(['ingresses'])
      + rbac.policyRule.withVerbs(['get', 'list', 'watch']),

    rbac.policyRule.withNonResourceURLs(['/metrics'])
      + rbac.policyRule.withVerbs(['get']),
  ],
  clusterRole: rbac.clusterRole.new(clusterName)
    + rbac.clusterRole.withRules(self.clusterRoleRules),
  clusterRoleBinding: rbac.clusterRoleBinding.new(clusterName)
    + rbac.clusterRoleBinding.roleRef.withApiGroup('rbac.authorization.k8s.io')
    + rbac.clusterRoleBinding.roleRef.withKind(self.clusterRole.kind)
    + rbac.clusterRoleBinding.roleRef.withName(self.clusterRole.metadata.name)
    + rbac.clusterRoleBinding.withSubjects([rbac.subject.fromServiceAccount(self.serviceAccount)]),

  local selectorsSpec = {
    spec+: {
      // If the selector is empty (NOT null), it matches everything.
      serviceMonitorSelector: {},
      serviceMonitorNamespaceSelector: {},
      podMonitorSelector: {},
      podMonitorNamespaceSelector: {},
      probeSelector: {},
      probeNamespaceSelector: {},
      scrapeConfigSelector: {},
      scrapeConfigNamespaceSelector: {},
      ruleSelector: {},
      ruleNamespaceSelector: {},
    }
  },

  prometheus: prometheus.new(clusterName)
    + prometheus.spec.withServiceAccountName(self.serviceAccount.metadata.name)
    + prometheus.spec.withPrometheusExternalLabelName('prom_cluster')  // I've set Mimir to use this to identify the Prometheus cluster
    + prometheus.spec.withReplicaExternalLabelName('__replica__') // Mimir uses this to deduplicate replicas
    + prometheus.spec.withExternalLabels({cluster: 'weebcluster'}) // Loki and Mimir use this to identify deployment cluster
    + prometheus.spec.withRemoteWrite(
        prometheus.spec.remoteWrite.withUrl('http://distributor.mimir:8080/api/v1/push')
        + prometheus.spec.remoteWrite.queueConfig.withMinShards(3),
      )
    + selectorsSpec,

  local servicePort = k.core.v1.servicePort.newNamed('web', 9090, 'web'),
  service: k.core.v1.service.new(clusterName, {prometheus: clusterName}, servicePort),

  ingress: utils.newStandardIngress(self.service, servicePort, appConfig),
};

weebcluster.newTankaEnv(envName, namespace, prometheusEnv)