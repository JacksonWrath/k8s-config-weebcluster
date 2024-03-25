local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local helm = import 'k3s-helm.libsonnet';

local envName = 'ingress-nginx';
local namespace = 'ingress-nginx';

local values = std.parseYaml(importstr 'values.yaml');

local certManagerEnv = {
  local chartConfig = {
    chartId: 'ingress-nginx',
    targetNamespace: namespace,
    values: values,
  },

  namespace: k.core.v1.namespace.new(namespace),

  helmChart: helm.newHelmChart(chartConfig),
};

weebcluster.newTankaEnv(envName, namespace, certManagerEnv)