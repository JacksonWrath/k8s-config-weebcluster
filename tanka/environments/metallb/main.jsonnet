local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local helm = import 'k3s-helm.libsonnet';

local envName = 'metallb';
local namespace = 'metallb';

local certManagerEnv = {
  local chartConfig = {
    chartId: 'metallb',
    targetNamespace: namespace,
  },

  namespace: k.core.v1.namespace.new(namespace),

  helmChart: helm.newHelmChart(chartConfig),
};

weebcluster.newTankaEnv(envName, namespace, certManagerEnv)