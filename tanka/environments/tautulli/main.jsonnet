local weebcluster = import 'weebcluster.libsonnet';

local envName = 'tautulli';
local namespace = 'plex';

local tautulliEnvironment = {
  local appName = 'tautulli',
  local image = 'tautulli/tautulli:latest',
  local ingressSubdomain = 'morgiana',
  local configVolSize = '1Gi',
  local httpPortNumber = 8181,

  tautulliApp: weebcluster.newStandardApp(appName, image, configVolSize, httpPortNumber, ingressSubdomain),
};

weebcluster.newTankaEnv(envName, namespace, tautulliEnvironment)