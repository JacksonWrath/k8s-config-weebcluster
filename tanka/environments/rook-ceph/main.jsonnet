local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local helm = import 'k3s-helm.libsonnet';

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
};

weebcluster.newTankaEnv(envName, namespace, certManagerEnv)