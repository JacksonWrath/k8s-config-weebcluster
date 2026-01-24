local k = import 'k.libsonnet';
local k3sHelm = import 'k3s-helm.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local tailscale = import 'tailscale.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';

local envName = 'tailscale';
local namespace = 'tailscale';

weebcluster.newTankaEnv(envName, namespace, {
  namespace: k.core.v1.namespace.new(namespace),

  helmChart: k3sHelm.newHelmChart({
    chartId: 'tailscale-operator',
    targetNamespace: namespace,
    values: {
      oauth: {
        clientId: private.tailscale.operator.oauth.clientId,
        clientSecret: private.tailscale.operator.oauth.clientSecret,
      },
    },
  }),

  connector:
    tailscale.v1alpha1.connector.new('weebcluster-connector', 'weebcluster-subnet-connector') +
    tailscale.v1alpha1.connector.withTags(['tag:weebcluster-subnet-connector']) +
    tailscale.v1alpha1.connector.withRoutes(['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16']) +
    tailscale.v1alpha1.connector.withExitNode(true),
})
