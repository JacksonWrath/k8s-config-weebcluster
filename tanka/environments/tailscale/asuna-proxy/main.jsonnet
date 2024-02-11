local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local tailscale = import '../tailscale.jsonnet';

local envName = 'tailscale-asuna';
local namespace = envName;

local config = {
  appName: 'tailscale-asuna-proxy',
  namespace: namespace,
  tailscaleDeviceHostname: 'asuna',
  secretStringData: private.tailscale.asunaProxy.secretStringData, // evaluates to { TS_AUTHKEY: '<a_tailscale_client_key>'}
  envMixin: {
    TS_DEST_IP: homelab.nfs.asuna.ipv4,
  },
};

weebcluster.newTankaEnv(envName, namespace, tailscale.generate(config))
