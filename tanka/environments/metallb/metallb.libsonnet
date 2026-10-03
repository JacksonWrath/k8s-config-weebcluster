local k = import 'k.libsonnet';
local helm = import 'k3s-helm.libsonnet';

{
  new(namespace):: {
    namespace: k.core.v1.namespace.new(namespace),
    helmChart: helm.newHelmChart({
      chartId: 'metallb',
      targetNamespace: namespace,
    }),
  },
}
