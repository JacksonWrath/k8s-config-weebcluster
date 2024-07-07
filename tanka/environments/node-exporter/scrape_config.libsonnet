// A scrape config for node-exporter which maps the nodename onto the instance label.

// This is a smol rewrite of the following to generate the fields needed for the Prometheus Operator ScrapeConfig CR.
// https://github.com/grafana/jsonnet-libs/blob/master/node-exporter/scrape_config.libsonnet

// Basically, it changes the key names from snake_case to camelCase.
// Also "relabelings", lmao.
// Honestly idk why these are different. I tried digging into old issues and proposals about it, but after seeing 
// references from 2018 I gave up. Maybe that WAS the original name and Prometheus is the one that changed?

// Why can't things just be consistent #jobsecurity

function(namespace) {
  jobName: '%s/node-exporter' % namespace,
  kubernetesSDConfigs: [{
    role: 'pod',
    namespaces: {
      names: [namespace],
    },
  }],

  relabelings: [
    // Drop anything whose name is not node-exporter.
    {
      sourceLabels: ['__meta_kubernetes_pod_label_name'],
      regex: 'node-exporter',
      action: 'keep',
    },

    // Rename instances to be the node name.
    {
      sourceLabels: ['__meta_kubernetes_pod_node_name'],
      action: 'replace',
      targetLabel: 'instance',
    },

    // But also include the namespace as a separate label, for routing alerts.
    {
      sourceLabels: ['__meta_kubernetes_namespace'],
      action: 'replace',
      targetLabel: 'namespace',
    },
  ],
}