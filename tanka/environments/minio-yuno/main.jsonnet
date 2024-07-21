local weebcluster = import 'weebcluster.libsonnet';
local k = import 'k.libsonnet';
local prometheusLib = import 'prometheus/main.libsonnet';

local envName = 'minioYuno';
local namespace = 'minio-yuno';

local minioYunoEnv = {
  // The tenant CR is still manually created through the Operator, until my fix for jsonnet-libs is merged so the MinIO
  // lib is generated correctly.

  // Why not use a ServiceMonitor?
  // Because any node will output the metrics for all nodes at the "cluster" endpoint.
  // If you scrape all nodes on this, you get duplicate series of each node-level metric.
  // I don't have a reason to go to the effort of scraping each node and figuring out if there's any duplicates for
  // "cluster-wide" metrics that each would emit, or possibly if there's metrics only at the "cluster" endpoint or not.
  // One could assume from docs that "cluster" is a convenience, but they aren't explicit on this point.
  local scrapeConfig = prometheusLib.monitoring.v1alpha1.scrapeConfig,
  local metricsPathTargets = ['cluster', 'bucket', 'resource'],
  minioScrapeConfigs: [
    scrapeConfig.new('minio-scrapeconfig-%s' % target)
      + scrapeConfig.spec.withStaticConfigs(scrapeConfig.spec.staticConfigs.withTargets(['minio.minio-yuno']))
      + scrapeConfig.spec.withMetricsPath('/minio/v2/metrics/%s' % target)
      + scrapeConfig.spec.withRelabelings([
          {
            // Add static label that identifies the deployment as a whole.
            // I use this in the dashboards instead of relying on the job name.
            // Prefixed with "minio-" because Mimir/Loki also use "tenant" and publish it as a label.
            action: 'replace',
            targetLabel: 'minio_tenant',
            replacement: 'yuno',
          },
          {
            // Replace instance label so it doesn't use the svc IP. I don't care to have this dimension.
            action: 'replace',
            targetLabel: 'instance',
            replacement: 'minio-svc'
          }
        ])
      + scrapeConfig.spec.withMetricRelabelings([
          {
            // I don't care to have this dimension. It's the hash of the build commit.
            action: 'labeldrop',
            regex: 'commit'
          },
          {
            // Replace the FQDN in the server label with just the hostname
            sourceLabels: ['server'],
            regex: '([a-zA-Z0-9-]+)\\..*',
            action: 'replace',
            targetLabel: 'server',
          },
        ])
    for target in metricsPathTargets
  ],
};

weebcluster.newTankaEnv(envName, namespace, minioYunoEnv)