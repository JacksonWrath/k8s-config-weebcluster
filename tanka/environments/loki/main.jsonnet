local weebcluster = import 'weebcluster.libsonnet';

local envName = 'loki';
local namespace = 'loki';

weebcluster.newTankaEnv(envName, namespace, import 'loki.jsonnet')
