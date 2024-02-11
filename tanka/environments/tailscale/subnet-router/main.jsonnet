local weebcluster = import 'weebcluster.libsonnet';
local tailscale = import '../tailscale.jsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';

local envName = 'tailscale';
local namespace = envName;

local config = {
  appName: 'tailscale-exit-node',
  namespace: namespace,
  tailscaleDeviceHostname: 'weebcluster-exit-node',
  secretStringData: private.tailscale.secret_stringData, // evaluates to { TS_AUTHKEY: '<a_tailscale_client_key>'}
  envMixin: {
      TS_EXTRA_ARGS: '--advertise-exit-node',
      TS_ROUTES: '10.0.0.0/8,172.16.0.0/12,192.168.0.0/16',
  }
};

weebcluster.newTankaEnv(envName, namespace, tailscale.generate(config))
