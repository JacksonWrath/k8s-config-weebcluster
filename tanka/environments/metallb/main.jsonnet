local weebcluster = import 'weebcluster.libsonnet';
local metallb = import 'metallb.libsonnet';
local metallbConfig = import 'metallb-config.libsonnet';

local namespace = 'metallb';

{
  'helm': weebcluster.newTankaEnv('helm', namespace, metallb.new(namespace)),
  'resources': weebcluster.newTankaEnv('resources', namespace, metallbConfig.new(namespace, weebcluster)),
}