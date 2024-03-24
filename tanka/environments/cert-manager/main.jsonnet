local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local helm = import 'k3s-helm.libsonnet';

local envName = 'cert-manager';
local namespace = 'cert-manager';

local certManagerEnv = {
  local chartConfig = {
    name: 'cert-manager',
    repo: 'https://charts.jetstack.io',
    chart: 'cert-manager',
    version: 'v1.12.4',
    targetNamespace: namespace,
    values: {
      installCRDs: true,
    },
  },

  namespace: k.core.v1.namespace.new(namespace),

  helmChart: helm.newHelmChart(chartConfig),

  // Note: the ClusterIssuers still have to be applied with kubectl.
};

weebcluster.newTankaEnv(envName, namespace, certManagerEnv)