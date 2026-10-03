local weebcluster = import 'weebcluster.libsonnet';
local bind9 = import 'bind9.libsonnet';

local envName = 'bind9';
local namespace = 'bind-dns';

weebcluster.newTankaEnv(envName, namespace, bind9.newBind9Environment(namespace, weebcluster))
