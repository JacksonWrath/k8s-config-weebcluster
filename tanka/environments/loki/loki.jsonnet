local gateway = import 'loki/gateway.libsonnet';
local loki = import 'loki/loki.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local prometheus = import 'prometheus/main.libsonnet';

local requestOverride(cpu=null, mem=null) = {
  resources+: {
    requests+: {
      [if cpu != null then 'cpu']: cpu,
      [if mem != null then 'memory']: mem,
    },
  },
};

local resourceRequestsOverrides = {
  ingester_container+:: requestOverride(mem='200Mi'),
  memcached_chunks+: {
    memcached_container+:: requestOverride(mem='100Mi'),
  },
  memcached_index_queries+: {
    memcached_container+:: requestOverride(mem='50Mi'),
  },
  memcached_frontend+: {
    memcached_container+:: requestOverride(mem='50Mi'),
  },
  distributor_container+:: requestOverride(mem='100Mi'),
  compactor_container+:: requestOverride(mem='100Mi'),
  querier_container+:: requestOverride(mem='100Mi'),
  query_frontend_container+:: requestOverride(mem='100Mi'),
};

local serviceMonitorOverrides = {
  serviceMonitor+: {
    spec+: {
      servicesToRelabel+: [
        'query-frontend',
        'ingester-zone-a',
        'ingester-zone-b',
        'ingester-zone-c',
      ],
    },
  },
};

loki + gateway {
  _images+:: {
    loki: 'grafana/loki:3.0.0',
    nginx: 'nginx:1.26-alpine',
  },
  _config+:: {
    namespace: 'loki',
    htpasswd_contents: private.loki.htpasswd_contents,

    create_service_monitor: true,

    storage_backend: 's3',
    s3_access_key: private.loki.s3_access_key,
    s3_secret_access_key: private.loki.s3_secret_access_key,
    s3_address: 'minio.minio-yuno',
    s3_bucket_name: 'loki',
    s3_path_style: true,

    using_boltdb_shipper: true,
    boltdb_shipper_shared_store: $._config.storage_backend,
    using_tsdb_shipper: true,
    tsdb_shipper_shared_store: $._config.storage_backend,

    querier_pvc_class: weebcluster.nvme_storage_class,
    ingester_pvc_class: weebcluster.nvme_storage_class,
    ruler_pvc_class: weebcluster.nvme_storage_class,
    compactor_pvc_class: weebcluster.nvme_storage_class,
    ingester_data_disk_class: weebcluster.nvme_storage_class,
    ingester_wal_disk_class: weebcluster.nvme_storage_class,

    loki+: {
      schema_config: {
        configs: [
          {
            from: '2023-10-01',
            store: 'boltdb-shipper',
            object_store: $._config.boltdb_shipper_shared_store,
            schema: 'v12',
            index: {
              prefix: '%s_index_' % $._config.table_prefix,
              period: '%dh' % $._config.index_period_hours,
            },
          },
          {
            from: '2024-07-03',
            store: 'tsdb',
            object_store: $._config.tsdb_shipper_shared_store,
            schema: 'v13',
            index: {
              prefix: '%s_index_' % $._config.table_prefix,
              period: '%dh' % $._config.index_period_hours,
            },
          },
        ],
      },
    },

    replication_factor: 3,
    consul_replicas: 1,
  },
  local loki_mixin = (import 'loki-mixin/recording_rules.libsonnet') + (import 'loki-mixin/config.libsonnet'),
  local prometheusRule = prometheus.monitoring.v1.prometheusRule,
  prometheusRecordingRule: prometheusRule.new('loki-prometheusrecordingrules')
    + prometheusRule.spec.withGroups(loki_mixin.prometheusRules.groups),
} 
+ resourceRequestsOverrides
+ serviceMonitorOverrides