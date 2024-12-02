local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local k = import 'k.libsonnet';
local utils = import 'utils.libsonnet';

// API aliases
local container = k.core.v1.container;

local envName = 'immich';
local namespace = 'immich';

local appConfig = weebcluster.defaultAppConfig + {
  appName: 'immich',
  image: weebcluster.images.immich.image,
};
local labels = {
  app: appConfig.appName,
};


local immichEnv = {
  local redisContainer = container.withImage(weebcluster.images.redis.image),
  redis: utils.newSinglePodDeployment('redis', [redisContainer], labels),

};

weebcluster.newTankaEnv(envName, namespace, immichEnv)