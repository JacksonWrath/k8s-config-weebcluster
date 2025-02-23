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
    loki: 'grafana/loki:3.4.2',
    nginx: 'nginx:1.27.3-alpine',
  },
  _config+:: {
    namespace: 'loki',
    htpasswd_contents: private.loki.htpasswd_contents,

    create_service_monitor: true,

    local storage_configs = {
      // These are here for switching to a different S3 backend.
      // Loki does not appear to support multiple S3 backend configs; this makes it easy to swap between the two when necessary.
      // (I initially did this when moving off of MinIO)
      ceph: {
        using_boltdb_shipper: false,
        storage_backend: 's3',
        s3_access_key: private.loki.ceph.s3_access_key,
        s3_secret_access_key: private.loki.ceph.s3_secret_access_key,
        s3_address: 'rook-ceph-rgw-objectify-me-daddy.rook-ceph',
        s3_bucket_name: 'loki',
        s3_path_style: true,
      },
    },

    local current_storage_config = storage_configs.ceph,

    storage_backend: current_storage_config.storage_backend,
    s3_access_key: current_storage_config.s3_access_key,
    s3_secret_access_key: current_storage_config.s3_secret_access_key,
    s3_address: current_storage_config.s3_address,
    s3_bucket_name: current_storage_config.s3_bucket_name,
    s3_path_style: current_storage_config.s3_path_style,

    using_boltdb_shipper: current_storage_config.using_boltdb_shipper,
    boltdb_shipper_shared_store: current_storage_config.storage_backend,
    using_tsdb_shipper: true,
    tsdb_shipper_shared_store: current_storage_config.storage_backend,

    querier_pvc_class: weebcluster.nvme_storage_class,
    ingester_pvc_class: weebcluster.nvme_storage_class,
    ruler_pvc_class: weebcluster.nvme_storage_class,
    compactor_pvc_class: weebcluster.nvme_storage_class,
    ingester_data_disk_class: weebcluster.nvme_storage_class,
    ingester_wal_disk_class: weebcluster.nvme_storage_class,

    loki+: {
      schema_config: {
        configs: std.filter( function(entry) entry != null, [
          if current_storage_config.using_boltdb_shipper then
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
        ]),
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