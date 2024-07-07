local weebcluster = import 'weebcluster.libsonnet';
local k = import 'k.libsonnet';

// The CoreOS etcd-operator, which is what this is using, was deprecated 5 years ago.
// I guess it still works since Grafana is still using it and linking to it in docs.
// There's a couple efforts for creating a new operator, but nothing solidified yet.
local etcdOperator = import 'etcd-operator/operator.libsonnet';

local envName = 'etcdOperator';
local namespace = 'etcd-operator';

local etcdOperatorEnv = {
  namespace: k.core.v1.namespace.new(namespace),
  operator: etcdOperator {
    _config+:: {
      namespace: namespace,
    }
  },
};

weebcluster.newTankaEnv(envName, namespace, etcdOperatorEnv)