local promtail = import 'promtail/promtail.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';

promtail {
  _images+:: {
    promtail: 'grafana/promtail:3.0.0',
  },
  _config+:: {
    namespace: 'promtail',

    promtail_config+: {
      clients: [{
        scheme:: 'http',
        hostname:: 'gateway.loki',
        username:: private.loki.gateway_username,
        password:: private.loki.gateway_password,
      }],
    },
  },

  // This "promtail_config" is what is rendered into the ConfigMap for the promtail config file
  promtail_config+:: (import 'k8s_scrape_config.libsonnet') + {
    scrape_configs+: [
      // Scrape config for systemd journal on each host
      {
        job_name: 'node-systemd-journal',
        journal: {
          labels: {
            job: 'node-systemd-journal',
          },
          path: '/var/log/journal', // The promtail daemonset already has '/var/log' mounted
        },
        relabel_configs: [
          {
            source_labels: ['__journal__systemd_unit'],
            target_label: 'systemd_unit',
          },
          {
            source_labels: ['__journal__hostname'],
            target_label: 'node_name',
          },
        ],
      },
    ],
  }
}