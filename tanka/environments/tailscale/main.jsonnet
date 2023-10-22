local weebcluster = import 'weebcluster.libsonnet';
local tailscale = import 'tailscale.jsonnet';

local envName = 'tailscale';
local namespace = 'tailscale';

local config = {
  image: 'ghcr.io/tailscale/tailscale:latest',
  appName: 'tailscale-exit-node',
  namespace: namespace,
  advertiseRoutes: '10.0.0.0/8,172.16.0.0/12,192.168.0.0/16',
  tailscaleDeviceHostname: 'weebcluster-exit-node',
};

weebcluster.newTankaEnv(envName, namespace, tailscale.generate(config))
