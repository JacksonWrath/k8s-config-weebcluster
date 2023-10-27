local kube = import '1.27/main.libsonnet';
local utils = import 'utils.libsonnet';

// Kubernetes API object variables
local pvc = kube.core.v1.persistentVolumeClaim;
local ingress = kube.networking.v1.ingress;
local ingressTLS = kube.networking.v1.ingressTLS;
local ingressRule = kube.networking.v1.ingressRule;
local httpIngressPath = kube.networking.v1.httpIngressPath;

{
  local weebcluster = self,
  ingressDomainSuffix: 'bukkake.cafe',

  // Cluster constants
  nvme_storage_class: 'nvme-rook-ceph',
  nginxIngressClass: 'nginx',

  // Inline Tanka environment
  newTankaEnv(name, namespace, data):: {
    apiVersion: 'tanka.dev/v1alpha1',
    kind: 'Environment',
    metadata: {
      name: name,
    },
    spec: {
      apiServer: 'https://aomine.bukkake.cafe:6443',
      namespace: namespace,
    },
    data: data,
  },

  newStandardApp(appName, image, configVolSize, httpPortNumber, ingressSubdomain, additionalLabels={}):: {
    local labels = {
      app: appName,
    } + additionalLabels,

    local configVolume = weebcluster.newConfigVolume(configVolSize, labels),
    
    container:: utils.newHttpContainer(appName, image, httpPortNumber) +
    kube.core.v1.container.withVolumeMounts([configVolume.volumeMount]),

    // Rendered manifests
    persistentVolumeClaim: configVolume.configPVC,

    deployment: utils.newSinglePodDeployment(appName, [self.container], labels) +
      kube.apps.v1.deployment.spec.template.spec.withVolumes([configVolume.volume]),

    service: utils.newHttpService(appName, self.deployment.spec.template.metadata.labels),

    ingress: weebcluster.newStandardHttpIngress(
      name=appName, 
      subdomain=ingressSubdomain, 
      service=self.service,
    ),
  },

  // Create a PVC with some cluster-specific defaults
  newStandardPVC(name, size, labels=null):: 
    pvc.new(name) + 
    pvc.spec.withStorageClassName(self.nvme_storage_class) +
    pvc.spec.withAccessModes(['ReadWriteOnce']) +
    pvc.spec.resources.withRequests({storage: size}) + 
    if labels != null then pvc.metadata.withLabelsMixin(labels) else {},

  // Generate objects necessary for a standard "config" volume
  newConfigVolume(size, labels):: {
    local volumeName = labels.app + '-config',
    configPVC:: weebcluster.newStandardPVC(volumeName, size, labels),
    volume:: utils.newVolumeFromPVC('config', self.configPVC),
    volumeMount:: kube.core.v1.volumeMount.new('config', '/config'),
  },

  // Create an Ingress with some cluster-specific defaults
  local ingressAnnotations = {
    'cert-manager.io/cluster-issuer': 'letsencrypt',
  },
  newStandardIngress(name, subdomain, service, servicePort, pathPrefix='/'):: 
    local tlsSecretName = name + '-tls';
    local host = subdomain + '.' + self.ingressDomainSuffix;
    local tls = ingressTLS.withHosts([host]) + ingressTLS.withSecretName(tlsSecretName);
    local backendService = 
      httpIngressPath.backend.service.withName(service.metadata.name) +
      httpIngressPath.backend.service.port.withName(servicePort.name);
    local path = httpIngressPath.withPath(pathPrefix) + httpIngressPath.withPathType('Prefix') + backendService;
    local rule = ingressRule.withHost(host) + ingressRule.http.withPaths([path]);

    ingress.new(name) +
    ingress.metadata.withAnnotations(ingressAnnotations) +
    ingress.spec.withTls([tls]) + 
    ingress.spec.withIngressClassName(self.nginxIngressClass) + 
    ingress.spec.withRules([rule]),

  // Create an standard Ingress pointed at the 'http' port of a given service
  newStandardHttpIngress(name, subdomain, service, pathPrefix='/')::
    local servicePort = kube.core.v1.servicePort.withName('http');
    self.newStandardIngress(name, subdomain, service, servicePort, pathPrefix)
}
