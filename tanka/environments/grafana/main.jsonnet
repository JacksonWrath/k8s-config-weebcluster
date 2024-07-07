local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local grafana = import 'grafana/grafana.libsonnet';

local envName = 'grafana';
local namespace = 'grafana';
local subdomain = 'grafana';
local hostname = subdomain + '.' + homelab.defaultDomain;

local datasources = {
  loki: grafana.datasource.new('Loki', 'http://gateway.loki', 'loki')
    + grafana.datasource.withBasicAuth(private.loki.gateway_username, private.loki.gateway_password),
  prometheus1: grafana.datasource.new('prometheus-1', 'http://prometheus-1.prometheus:9090', 'prometheus'),
};

local dashboards = {
  // These are available on grafana.com. IDs are commented by each.
  // e.g. grafana.com/grafana/dashboards/<ID>
  node_exporter_full: import 'rfmoz-grafana-dashboards/node-exporter-full.json', // 1860
};

local grafanaEnv = {
  namespace: k.core.v1.namespace.new(namespace),
  grafanaApp: grafana
    + grafana.withImage('grafana/grafana:11.1.0')
    + grafana.withRootUrl('https://' + hostname)
    + grafana.withTheme('dark')
    + grafana.withAnonymous()
    // Datasources
    + grafana.addDatasource('loki', datasources.loki)
    + grafana.addDatasource('prometheus-1', datasources.prometheus1)
    // Dashboards
    + grafana.addDashboard('node-exporter-full', dashboards.node_exporter_full, 'Node Exporter Full'),

  ingress: weebcluster.newStandardHttpIngress('grafana', subdomain, self.grafanaApp.grafana_service),
};

// Possible config I'll need later for postgres setup

// local test = {
//   _config+:: {
//     grafana_ini+: {
//       sections+: {
//         database: {
//           type: 'postgres',
//           host: '',
//           name: 'grafana',
//           user: '',
//           password: '',
//           ssl_mode: 'disable',
//         },
//       }
//     }
//   },
// };

weebcluster.newTankaEnv(envName, namespace, grafanaEnv) + {
  spec+: {
    applyStrategy: 'server', // "last-applied-configuration" is too long with client-side apply. Dashboards are huge.
  },
}