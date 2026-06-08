local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';
local pihole = import 'pihole.libsonnet';

local namespace = 'pihole';

{
    [cluster.name]: utils.newTankaEnv(cluster, namespace, pihole.newPiholeEnvironment(namespace, cluster))
    for cluster in homelab.k8s.clusters
}
