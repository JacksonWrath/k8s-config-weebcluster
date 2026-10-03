local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local helm = import 'k3s-helm.libsonnet';

local envName = 'csi-driver-nfs';
local namespace = 'kube-system';

local csiDriverNfsEnv = {
  local chartConfig = {
    chartId: 'csi-driver-nfs',
    targetNamespace: namespace,
    values: {
      controller: {
        runOnControlPlane: true,
      },
    },
  },

  helmChart: helm.newHelmChart(chartConfig),
};

weebcluster.newTankaEnv(envName, namespace, csiDriverNfsEnv)