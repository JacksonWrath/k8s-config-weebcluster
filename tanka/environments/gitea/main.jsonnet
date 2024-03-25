local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local helm = import 'k3s-helm.libsonnet';

local envName = 'gitea';
local namespace = 'gitea';
local hostname = 'kise' + '.' + weebcluster.ingressDomainSuffix;

local valuesStr = std.strReplace(importstr 'values.yaml', 'HOSTNAME_REPLACE_KEY', hostname);
local values = std.parseYaml(valuesStr);

local certManagerEnv = {
  local chartConfig = {
    chartId: 'gitea',
    targetNamespace: namespace,
    values: values,
  },

  namespace: k.core.v1.namespace.new(namespace),

  helmChart: helm.newHelmChart(chartConfig),
};

weebcluster.newTankaEnv(envName, namespace, certManagerEnv)