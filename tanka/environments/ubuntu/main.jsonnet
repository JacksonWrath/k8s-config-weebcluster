local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local utils = import 'utils.libsonnet';
local k = import 'k.libsonnet';

// This is basically a jumpbox for interacting with things inside the cluster

local envName = 'ubuntu';
local namespace = 'ubuntu';
local appName = 'ubuntu';
local image = weebcluster.images.ubuntu.image;
local labels = {
  app: appName,
};

local ubuntuEnv = {
  namespace: k.core.v1.namespace.new(namespace),
  local container = k.core.v1.container,
  container:: container.new(appName, image)
    + container.withCommand(['/bin/bash', '-c', 'while true; do sleep 60; done']),
  deployment: utils.newSinglePodDeployment(appName, [self.container], labels),
};

weebcluster.newTankaEnv(envName, namespace, ubuntuEnv)