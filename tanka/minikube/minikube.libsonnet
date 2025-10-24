local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';

{
  local minikube = self,

  // Import images lib so apps don't need to import it separately
  // It is a separate lib to make scripting updates to it easier
  local imageLib = import 'images.libsonnet',
  images: imageLib.images,

  // Constants
  defaultStorageClass: 'standard',
  ingressClass: 'nginx',
  primaryDomains: ['minikube.kazane'],

  defaultAppConfig: utils.appConfig + {
    configVolStorageClass: minikube.defaultStorageClass,
    primaryDomains: minikube.primaryDomains,
    ingressClass: minikube.ingressClass,
    tlsEnabled: false,
    useStagingCertIssuer: true,
  },

  // Inline Tanka environment
  newTankaEnv(port, envName, namespace, data):: 
    utils.newTankaEnv('https://127.0.0.1:%d' % port, envName, namespace, data),

  newStandardApp(appConfig)::
    utils.newStandardApp(minikube.defaultAppConfig + appConfig),
}