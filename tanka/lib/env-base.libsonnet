{
  apiVersion: 'tanka.dev/v1alpha1',
  kind: 'Environment',
  metadata: {
    name: $._env.name,
  },
  spec: {
    apiServer: 'https://aomine.bukkake.cafe:6443',
    namespace: $._env.namespace,
  },
  data: error 'must provide environment data',
  _env:: {
    name: error 'must specify environment name',
    namespace: error 'must specify namespace',
  }
}