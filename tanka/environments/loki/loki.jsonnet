local gateway = import 'loki/gateway.libsonnet';
local loki = import 'loki/loki.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';

loki + gateway {
  _config+:: {
    namespace: 'loki',
    htpasswd_contents: private.loki.htpasswd_contents,

    storage_backend: 's3',
    s3_access_key: private.loki.s3_access_key,
    s3_secret_access_key: private.loki.s3_secret_access_key,
    s3_address: 'minio.minio-yuno',
    s3_bucket_name: 'loki',
    s3_path_style: true,

    boltdb_shipper_shared_store: $._config.storage_backend,

    querier_pvc_class: weebcluster.nvme_storage_class,
    ingester_pvc_class: weebcluster.nvme_storage_class,
    ruler_pvc_class: weebcluster.nvme_storage_class,
    compactor_pvc_class: weebcluster.nvme_storage_class,
    ingester_data_disk_class: weebcluster.nvme_storage_class,

    loki+: {
      schema_config: {
        configs: [{
          from: '2023-10-01',
          store: 'boltdb-shipper',
          object_store: $._config.boltdb_shipper_shared_store,
          schema: 'v12',
          index: {
            prefix: '%s_index_' % $._config.table_prefix,
            period: '%dh' % $._config.index_period_hours,
          },
        }],
      },
    },

    replication_factor: 3,
    consul_replicas: 1,
  },
}