(import 'env-base.libsonnet') {
  _env+:: {
    name: 'promtail',
    namespace: 'promtail',
  },
  data: import 'promtail.jsonnet',
}