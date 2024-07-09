local charts = import 'charts.libsonnet';

{
  newHelmChart(chartConfig):: self.newHelmChartBase() + {
    local chart = charts[chartConfig.chartId],
    metadata: {
      name: chart.name,
      namespace: std.get(chartConfig, 'resourceNamespace', 'helmcharts'),
    },
    spec: {
      chart:
        if std.objectHas(chart, 'oci')
        then chart.oci
        else chart.name,
      [if std.objectHas(chart, 'repo') then 'repo']: chart.repo,
      version: chart.version,
      targetNamespace: chartConfig.targetNamespace,
      [if std.objectHas(chartConfig, 'values') then 'valuesContent']: 
        std.manifestYamlDoc(chartConfig.values, indent_array_in_object=false, quote_keys=false),
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