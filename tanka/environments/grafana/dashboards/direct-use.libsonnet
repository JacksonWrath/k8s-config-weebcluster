// These are dashboards that can just be imported as-is.
// Ones that are available on grafana.com will have the ID commeted by it.
// e.g. grafana.com/grafana/dashboards/<ID>

{
  node_exporter: {
    folder: 'node-exporter',
    grafanaDashboards: {
      node_exporter_full: import 'rfmoz-grafana-dashboards/node-exporter-full.json', // 1860
    },
  },
}