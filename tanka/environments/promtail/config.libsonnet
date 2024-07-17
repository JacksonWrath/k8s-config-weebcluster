local private = import 'libsonnet-secrets/rewt.libsonnet';

{
  _images+:: {
    promtail: 'grafana/promtail:3.0.0',
  },
  _config+:: {
    namespace: 'promtail',
    pipeline_stages: [
      {
        cri: {},
      },
      {
        static_labels: {
          cluster: 'weebcluster',
        },
      },
    ],

    promtail_config+: {
      clients: [{
        scheme:: 'http',
        hostname:: 'gateway.loki',
        username:: private.loki.gateway_username,
        password:: private.loki.gateway_password,
      }],
    },
  },
}