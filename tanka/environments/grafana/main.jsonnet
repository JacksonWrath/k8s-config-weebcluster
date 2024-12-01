local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local grafana = import 'grafana/grafana.libsonnet';
local cnpg = import 'cnpg/main.libsonnet';

// API object aliases
local pgCluster = cnpg.postgresql.v1.cluster;

local envName = 'grafana';
local namespace = 'grafana';

local appConfig = weebcluster.defaultAppConfig + {
  appName: 'grafana',
  subdomain: 'grafana',
};

local pgClusterName = 'postgres';
local pgDatabaseName = 'grafana';

local iniConfig = {
  sections+: {
    database: {
      type: 'postgres',
      host: '%s-rw.%s:5432' % [pgClusterName, namespace],
      name: pgDatabaseName,
      user: private.grafana.pgsqlSecretData.username,
      password: private.grafana.pgsqlSecretData.password,
    }
  }
};

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

  postgresUserSecret: k.core.v1.secret.new('postgres-user-grafana', {})
    + k.core.v1.secret.withStringData(private.grafana.pgsqlSecretData),

  postgresCluster: pgCluster.new(pgClusterName)
    + pgCluster.spec.withImageName(weebcluster.images.cnpgPostgres.image)
    + pgCluster.spec.withInstances(1)
    + pgCluster.spec.bootstrap.initdb.withDatabase(pgDatabaseName)
    + pgCluster.spec.bootstrap.initdb.secret.withName(self.postgresUserSecret.metadata.name)
    + pgCluster.spec.storage.withSize('1Gi'),

  grafanaApp: grafana
    + grafana.withImage(weebcluster.images.grafana.image)
    + grafana.withRootUrl('https://%s.%s' % [appConfig.subdomain, homelab.defaultDomain])
    + grafana.withGrafanaIniConfig(iniConfig)
    + grafana.withTheme('dark')
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
              [name]+: dashboardGroup.grafanaDashboards[name] + { editable: true }
              for name in std.objectFields(dashboardGroup.grafanaDashboards)
            }
          }
          for dashboardGroup in std.objectValues(import 'dashboards.libsonnet')
        }
      },

  ingress: utils.newStandardHttpIngress(self.grafanaApp.grafana_service, appConfig),
};

weebcluster.newTankaEnv(envName, namespace, grafanaEnv)