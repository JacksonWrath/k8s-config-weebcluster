local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local helm = import 'k3s-helm.libsonnet';

local envName = 'grafana';
local namespace = 'grafana';
local hostname = 'grafana' + '.' + homelab.defaultDomain;

local valuesStr = std.strReplace(importstr 'values.yaml', 'HOSTNAME_REPLACE_KEY', hostname);
local values = std.parseYaml(valuesStr);

local certManagerEnv = {
  local chartConfig = {
    chartId: 'grafana',
    targetNamespace: namespace,
    values: values,
  },

  namespace: k.core.v1.namespace.new(namespace),

  helmChart: helm.newHelmChart(chartConfig),
};

weebcluster.newTankaEnv(envName, namespace, certManagerEnv)