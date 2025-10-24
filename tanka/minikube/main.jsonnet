local minikube = import 'minikube.libsonnet';
local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local k = import 'k.libsonnet';
local cnpg = import 'cnpg/main.libsonnet';
local grafana = import'grafana/grafana.libsonnet';

// API object aliases
local podTemplateSpec = k.apps.v1.deployment.spec.template.spec;
local container = k.core.v1.container;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;
local pgCluster = cnpg.postgresql.v1.cluster;

local envName = 'pgsql';
local namespace = 'pgsql-test';

local currentMinikubePort = 60091;

local appConfig = minikube.defaultAppConfig + {
  appName: 'grafana',
  subdomain: 'grafana',
};

local pgClusterName = 'grafana-postgres';
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

local minikubeEnv = {
  namespace: k.core.v1.namespace.new(namespace),
  
  pgSecret: k.core.v1.secret.new('grafana-postgres-user', {})
    + k.core.v1.secret.withStringData(private.grafana.pgsqlSecretData),

  cluster: cnpg.postgresql.v1.cluster.new(pgClusterName)
    + pgCluster.spec.withImageName(minikube.images.cnpgPostgres.image)
    + pgCluster.spec.withInstances(1)
    + pgCluster.spec.bootstrap.initdb.withDatabase(pgDatabaseName)
    + pgCluster.spec.bootstrap.initdb.secret.withName(self.pgSecret.metadata.name)
    + pgCluster.spec.storage.withSize('1Gi'),

  grafana: grafana
    + grafana.withImage('grafana/grafana:11.3.0')
    + grafana.withGrafanaIniConfig(iniConfig)
    + grafana.withRootUrl('http://grafana.minikube.kazane'),

  ingress: utils.newStandardHttpIngress(self.grafana.grafana_service, appConfig)
};

minikube.newTankaEnv(currentMinikubePort, envName, namespace, minikubeEnv)
