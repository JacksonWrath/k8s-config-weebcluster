local weebcluster = import 'weebcluster.libsonnet';
local k = import 'k.libsonnet';
local helm = import 'k3s-helm.libsonnet';

local envName = 'mongodbOperator';
local namespace = 'mongodb-operator';

local mongodbOperatorEnv = {
  local chartConfig = {
    chartId: 'mongodb-operator',
    targetNamespace: namespace,
    values: {
      operator: {
        watchNamespace: '*',
      },
    },
  },

  namespace: k.core.v1.namespace.new(namespace),

  helmChart: helm.newHelmChart(chartConfig),
};

weebcluster.newTankaEnv(envName, namespace, mongodbOperatorEnv)