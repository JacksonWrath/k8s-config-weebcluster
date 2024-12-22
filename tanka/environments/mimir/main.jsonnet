local weebcluster = import 'weebcluster.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local helm = import 'k3s-helm.libsonnet';
local k = import 'k.libsonnet';

local mimir = import 'mimir/mimir.libsonnet';
local prometheusLib = import 'prometheus/main.libsonnet';

local envName = 'mimir';
local namespace = 'mimir';

local mimirEnv = {
  namespace: k.core.v1.namespace.new(namespace),
  mimir: mimir {
    // _images+:: can go here if needed later; fortunately they actually have it up to date right now.
    _config+:: {
      namespace: namespace,

      local storage_configs = {
        minio: {
          storage_backend: 's3',
          storage_s3_access_key_id: private.mimir.minio.s3_access_key,
          storage_s3_secret_access_key: private.mimir.minio.s3_secret_access_key,
          storage_s3_endpoint: 'minio.minio-yuno',
        },
        ceph: {
          storage_backend: 's3',
          storage_s3_access_key_id: private.mimir.ceph.s3_access_key,
          storage_s3_secret_access_key: private.mimir.ceph.s3_secret_access_key,
          storage_s3_endpoint: 'rook-ceph-rgw-objectify-me-daddy.rook-ceph',
        },
      },

      local current_storage_config = storage_configs.ceph,

      storage_backend: current_storage_config.storage_backend,
      storage_s3_access_key_id: current_storage_config.storage_s3_access_key_id,
      storage_s3_secret_access_key: current_storage_config.storage_s3_secret_access_key,
      storage_s3_endpoint: current_storage_config.storage_s3_endpoint,

      blocks_storage_bucket_name: 'mimir-blocks',

      alertmanager_data_disk_class: weebcluster.nvme_storage_class,
      ingester_data_disk_class: weebcluster.nvme_storage_class,
      store_gateway_data_disk_class: weebcluster.nvme_storage_class,
      compactor_data_disk_class: weebcluster.nvme_storage_class,

      limits: self.overrides.medium_user + {
        compactor_blocks_retention_period: '0',
      },
    },

    // Unfortunately, Grafana's jsonnet examples yet again aren't functional OOTB.
    // The etcd-operator it's using stopped working on k8s 1.22+, a year before Mimir was even launched, and 
    // was deprecated 2 years before that.
    //
    // Instead, set up an etcd cluster using the Bitnami helm chart. There's really not much of a suitable alternative
    // right now, apart from completely developing it myself. Not worth.
    local chartConfig = {
      chartId: 'etcd',
      targetNamespace: namespace,
      values: {
        global: {
          storageClass: weebcluster.nvme_storage_class,
        },
        auth: {
          rbac: {
            create: false,
          },
        },
        replicaCount: 3,
        autoCompactionRetention: '1h',
      },
    },
    etcd: helm.newHelmChart(chartConfig),

    // Additional args on components. It honestly kinda sucks that they don't expose these config options.
    // This is likely to break when additional components are added.

    // Disable auth, basically.
    local no_multitenancy = { 'auth.multitenancy-enabled': false },
    // I don't have Let's Encrypt set up for Minio, so it needs to use HTTP
    local insecure_s3 = { 'common.storage.s3.insecure': true },
    // HA config to add to distributor
    local ha_config = {
      // The etcd endpoint is hard-coded, expecting the naming from the deprecated operator. Override that.
      'distributor.ha-tracker.etcd.endpoints': 'etcd.%(namespace)s.svc.cluster.local:2379' % namespace,
      // Some of Mimir's and Loki's dashboards use "cluster" to define the compute cluster, not Prometheus, so I've
      // changed the external label that Prometheus uses to identify itself.
      'distributor.ha-tracker.cluster': 'prom_cluster',
    },

    distributor_args+:: ha_config + no_multitenancy,
    compactor_args+:: insecure_s3 + no_multitenancy,
    ingester_args+:: insecure_s3 + no_multitenancy,
    store_gateway_args+:: insecure_s3 + no_multitenancy,
    querier_args+:: insecure_s3 + no_multitenancy,
    query_frontend_args+:: no_multitenancy,
    query_scheduler_args+:: no_multitenancy,

    // Reduce resource requests
    local kausal = import 'ksonnet-util/kausal.libsonnet',
    compactor_container+: kausal.util.resourcesRequests('100m', '128Mi'),
    distributor_container+: kausal.util.resourcesRequests('100m', '128Mi'),
    ingester_container+: kausal.util.resourcesRequests('100m', '128Mi'),
    querier_container+: kausal.util.resourcesRequests('100m', '128Mi'),
    store_gateway_container+: kausal.util.resourcesRequests('100m', '128Mi'),
    query_frontend_container+: kausal.util.resourcesRequests('100m', '128Mi'),

    local smallMemcached = {
      cpu_requests:: '100m',
      memory_limit_mb:: 128,
      memory_request_overhead_mb:: 8,
      statefulSet+: kausal.apps.v1.statefulSet.mixin.spec.withReplicas(1),
    },

    memcached_chunks+: smallMemcached,
    memcached_frontend+: smallMemcached,
    memcached_index_queries+: smallMemcached,
    memcached_metadata+: smallMemcached,

  },

  // Service monitor for scraping Mimir
  local services = [
    'compactor',
    'distributor',
    'ingester',
    'querier',
    'query-frontend',
    'query-scheduler',
    'store-gateway',
  ],

  local relabelings = [
    {
      sourceLabels: ['job'],
      action: 'replace',
      targetLabel: 'job',
      replacement: namespace + '/$1',
    },
  ],

  local serviceMonitor = prometheusLib.monitoring.v1.serviceMonitor,
  mimirServiceMonitor: serviceMonitor.new('mimir-servicemonitor')
    + serviceMonitor.spec.selector.withMatchExpressions({
        key: 'name',
        operator: 'In',
        values: services,
      })
    + serviceMonitor.spec.withEndpoints(
        [
          serviceMonitor.spec.endpoints.withPort(component + '-http-metrics')
          + serviceMonitor.spec.endpoints.withHonorLabels(true)
          + serviceMonitor.spec.endpoints.withRelabelings(relabelings),
          for component in services
        ]
      ),
  
  local mimir_mixin = (import 'mimir-mixin/mixin.libsonnet'),
  local prometheusRule = prometheusLib.monitoring.v1.prometheusRule,
  mimirPrometheusRule: prometheusRule.new('mimir-prometheusrecordingrules')
    + prometheusRule.spec.withGroups(mimir_mixin.prometheusRules.groups),
};

weebcluster.newTankaEnv(envName, namespace, mimirEnv)