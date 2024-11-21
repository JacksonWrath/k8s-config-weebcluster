local weebcluster = import 'weebcluster.libsonnet';

local envName = 'tautulli';
local namespace = 'plex';

local appConfig = {
  appName: 'tautulli',
  image: weebcluster.images.tautulli.image,
  subdomain: 'morgiana',
  configVolSize: '1Gi',
  httpPortNumber: 8181,
};

local tautulliEnvironment = {
  tautulliApp: weebcluster.newStandardApp(appConfig),
};

weebcluster.newTankaEnv(envName, namespace, tautulliEnvironment)