local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';

local envName = 'helmcharts';
local namespace = 'helmcharts';

local helmchartsEnv = {
  namespace: k.core.v1.namespace.new(namespace),
};

weebcluster.newTankaEnv(envName, namespace, helmchartsEnv)
