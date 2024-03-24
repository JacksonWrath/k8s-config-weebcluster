{
  newHelmChart(chartConfig):: self.newHelmChartBase() + {
    metadata: {
      name: chartConfig.name,
      namespace: std.get(chartConfig, 'namespace', 'helmcharts'),
    },
    spec: {
      repo: chartConfig.repo,
      chart: chartConfig.chart,
      version: chartConfig.version,
      targetNamespace: chartConfig.targetNamespace,
      valuesContent: std.manifestYamlDoc(chartConfig.values, indent_array_in_object=false, quote_keys=false),
    },
  },
  
  newHelmChartBase():: {
    apiVersion: "helm.cattle.io/v1",
    kind: "HelmChart",
  },

  withName(name):: {
    metadata+: {
      name: name,
    },
  },

  withNamespace(namespace):: {
    metadata+: {
      namespace: namespace,
    },
  },

  withTargetNamespace(namespace):: {
    spec+: {
      targetNamespace: namespace,
    },
  },

  withChart(chart):: {
    spec+: {
      chart: chart,
    },
  },

  withVersion(version):: {
    spec+: {
      version: version,
    },
  },

  withRepo(repo):: {
    spec+: {
      repo: repo,
    },
  },

  withValuesContent(values):: {
    spec+: {
      valuesContent: values,
    },
  },
}