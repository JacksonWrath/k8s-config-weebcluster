local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';
local bind9 = import 'bind9.libsonnet';

local namespace = 'bind-dns';

{
    [cluster.name]: utils.newTankaEnv(cluster, namespace, bind9.newBind9Environment(namespace, cluster))
    for cluster in homelab.k8s.clusters
}
