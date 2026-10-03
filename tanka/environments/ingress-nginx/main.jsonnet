local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local helm = import 'k3s-helm.libsonnet';

local envName = 'ingress-nginx';
local namespace = 'ingress-nginx';

local values = {
  controller: {
    config: {
      'whitelist-source-range': '10.0.0.0/8,172.16.0.0/12,192.168.0.0/16',
    },
    service: {
      annotations: {
        'metallb.universe.tf/loadBalancerIPs': weebcluster.ipv4.ingress,
      },
      externalTrafficPolicy: 'Local',
    },
    allowSnippetAnnotations: true,
  },
  tcp: {
    '22': 'gitea/gitea-ssh:22',
    '9109': 'graphite-exporter/ingest:9109',
  },
  udp: {
    '9109': 'graphite-exporter/ingest:9109',
  },
};

local ingressNginxEnv = {
  local chartConfig = {
    chartId: 'ingress-nginx',
    targetNamespace: namespace,
    values: values,
  },

  namespace: k.core.v1.namespace.new(namespace),

  helmChart: helm.newHelmChart(chartConfig),
};

weebcluster.newTankaEnv(envName, namespace, ingressNginxEnv)