{
  // MinIO dashboards
  // Their official dashboards were designed for UI import; they need to be modified to not rely on input from that,
  // and instead just have another variable for the datasource.
  // Additionally, it uses the job label as the only variable, which is stupid.
  local clusterStr = importstr 'minio-grafana/minio-dashboard.json',
  local bucketStr = importstr 'minio-grafana/bucket/minio-bucket.json',
  // Replace all references to the input with the template variable
  local clusterReplace1Str = std.strReplace(clusterStr, 'DS_PROMETHEUS', 'datasource'),
  local bucketReplace1Str = std.strReplace(bucketStr, 'DS_PROMETHEUS', 'datasource'),
  // Replace all references to the job label with the tenant label
  local clusterReplace2Str = std.strReplace(clusterReplace1Str, 'job=~\\"$scrape_jobs\\"', 'minio_tenant=\\"$tenant\\"'),
  local bucketReplace2Str = std.strReplace(bucketReplace1Str, 'job=\\"$scrape_jobs\\"', 'minio_tenant=\\"$tenant\\"'),
  // That's not a typo; cluster uses =~, bucket uses =

  local clusterDashboard = std.parseJson(clusterReplace2Str),
  local bucketDashboard = std.parseJson(bucketReplace2Str),

  // The only templating variable in the source is the scrape job. Override it entirely.
  local templating = {
    templating: {
      list: [
        {
          current: {
            selected: false,
            text: 'default',
            value: 'default',
          },
          hide: 0,
          includeAll: false,
          label: 'Datasource',
          multi: false,
          name: 'datasource',
          query: 'prometheus',
          refresh: 1,
          skipUrlSync: false,
          type: 'datasource',
        },
        {
          datasource: {
            type: 'prometheus',
            uid: '${datasource}'
          },
          definition: 'label_values(minio_tenant)',
          label: 'Tenant',
          multi: false,
          name: 'tenant',
          query: {
            query: 'label_values(minio_vtenant)',
            refId: 'StandardVariableQuery',
          },
          refresh: 1,
          type: 'query',
        }
      ],
    },
  },

  minio: {
    folder: 'MinIO',
    grafanaDashboards: {
      cluster: clusterDashboard + templating,
      bucket: bucketDashboard + templating,
    },
  },
}