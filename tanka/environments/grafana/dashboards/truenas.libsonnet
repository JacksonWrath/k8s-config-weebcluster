{
  // TrueNAS dashboards
  // The ones I'm sourcing were designed for UI import; they need to be modified to not rely on input from that, and
  // instead just have another variable for the datasource (that's how the node-exporter-full dashbaord works)
  local truenasStr = importstr 'truenas-graphite-to-prometheus/dashboards/truenas_scale.json',
  local diskInsightsStr = importstr 'truenas-graphite-to-prometheus/dashboards/truenas_scale_disk_insights.json',
  local truenasDashboard = std.parseJson(std.strReplace(truenasStr, 'DS_MIMIR', 'datasource')),
  local diskInsightsDashboard = std.parseJson(std.strReplace(diskInsightsStr, 'DS_MIMIR', 'datasource')),

  local datasourceTemplating = {
    templating+: {
      list+: [
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
      ],
    },
  },
  local defaultTruenasJob = 'truenas',
  local setCurrentJob = {
    templating+: {
      list: [
        // I'm doing this to set the default job for the dashboard. I fucked up the graphite-exporter ServiceMonitor
        // initially and forgot the honorLabels config, so Prometheus rewrote the labels to the graphite-exporter for
        // the first little bit. Because it's lexographically before "truenas", they became the default.
        // If/when I configure data retention and those fall off, I won't need this, but that's likely years away.
        if var.name == 'job'
        then var { current: { text: defaultTruenasJob, value: defaultTruenasJob } }
        else var
        for var in super.list
      ],
    },
  },

  truenas: {
    folder: 'TrueNAS',
    grafanaDashboards: {
      truenas: truenasDashboard + setCurrentJob + datasourceTemplating,
      truenasDiskInsights: diskInsightsDashboard + setCurrentJob + datasourceTemplating,
    },
  },
}