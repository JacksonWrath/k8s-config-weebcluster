(import 'env-base.libsonnet') {
  _env+:: {
    name: 'tailscale',
    namespace: 'tailscale',
  },
  data: (import 'tailscale.jsonnet') + {
    _config+:: {
      namespace: $._env.namespace,
    }
  },
}