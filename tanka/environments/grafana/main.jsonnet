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
  mimir: grafana.datasource.new('Mimir', 'http://query-frontend.mimir:8080/prometheus', 'prometheus', true)
    + grafana.datasource.withJsonData({
      prometheusType: 'Mimir',
      PrometheusVersion: '2.9.1', 
      // This evaluates to "> 2.9.x" in Grafana currently. It's probably just a feature-gate.
      // Will have to keep an eye on this when I update Grafana.
    }),
};

local dashboards = import 'dashboards.libsonnet';
local dashboardsLib = import 'grafana/dashboards.libsonnet';

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
    + grafana.addDatasource('mimir', datasources.mimir)
    // Dashboards
    + {
        grafanaDashboardFolders+: {
          [dashboardGroup.folder]+: {
            id: dashboardsLib.folderID(dashboardGroup.folder),
            name: dashboardGroup.folder,
            dashboards+: {
              [name]+: dashboardGroup.grafanaDashboards[name]
              for name in std.objectFields(dashboardGroup.grafanaDashboards)
            }
          }
          for dashboardGroup in std.objectValues(import 'dashboards.libsonnet')
        }
      },

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

weebcluster.newTankaEnv(envName, namespace, grafanaEnv)