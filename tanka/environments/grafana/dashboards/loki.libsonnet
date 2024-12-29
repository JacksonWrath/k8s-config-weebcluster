{
  loki: (import 'loki-mixin/dashboards.libsonnet') + 
    (import 'loki-mixin/config.libsonnet') +
    {
      _config+:: {
        promtail: {
          enabled: false,
        },
        blooms: {
          enabled: false,
        },
      },
      folder: 'Loki',
    }
}