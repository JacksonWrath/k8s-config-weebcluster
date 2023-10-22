local weebcluster = import 'weebcluster.libsonnet';

local envName = 'promtail';
local namespace = 'promtail';

weebcluster.newTankaEnv(envName, namespace, import 'promtail.jsonnet')
