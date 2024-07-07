local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local k = import 'k.libsonnet';

local envName = 'ENV_NAME';
local namespace = 'NAMESPACE';

local ENV_NAMEEnv = {

};

weebcluster.newTankaEnv(envName, namespace, ENV_NAMEEnv)