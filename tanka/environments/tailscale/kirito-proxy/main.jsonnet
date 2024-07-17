local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local tailscale = import '../tailscale.jsonnet';

local envName = 'tailscale-kirito';
local namespace = envName;

local config = {
  appName: 'tailscale-kirito-proxy',
  namespace: namespace,
  tailscaleDeviceHostname: 'kirito',
  secretStringData: private.tailscale.kiritoProxy.secretStringData, // evaluates to { TS_AUTHKEY: '<a_tailscale_client_key>'}
  envMixin: {
    TS_DEST_IP: homelab.nfs.kirito.ipv4,
  },
};

weebcluster.newTankaEnv(envName, namespace, tailscale.generate(config))
