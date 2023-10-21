(import 'env-base.libsonnet') {
  _env+:: {
    name: 'loki',
    namespace: 'loki',
  },
  data: import 'loki.jsonnet',
}