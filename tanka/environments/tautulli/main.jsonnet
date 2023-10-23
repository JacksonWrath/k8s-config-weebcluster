local weebcluster = import 'weebcluster.libsonnet';

local envName = 'tautulli';
local namespace = 'plex';

weebcluster.newTankaEnv(envName, namespace, import 'tautulli.jsonnet')