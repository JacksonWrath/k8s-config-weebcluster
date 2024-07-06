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
};

local grafanaEnv = {
  namespace: k.core.v1.namespace.new(namespace),
  grafanaApp: grafana
    + grafana.withImage('grafana/grafana:11.1.0')
    + grafana.withRootUrl('https://' + hostname)
    + grafana.withTheme('dark')
    + grafana.withAnonymous()
    + grafana.addDatasource('Loki', datasources.loki),

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