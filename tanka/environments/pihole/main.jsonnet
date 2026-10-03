local weebcluster = import 'weebcluster.libsonnet';
local pihole = import 'pihole.libsonnet';

local envName = 'pihole';
local namespace = 'pihole';

weebcluster.newTankaEnv(envName, namespace, pihole.newPiholeEnvironment(namespace, weebcluster))
