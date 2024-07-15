{
  loki: (import 'loki-mixin/dashboards.libsonnet') + {
    _config+:: {
      promtail: {
        enabled: false,
      },
    },
    folder: 'Loki',
  }
}