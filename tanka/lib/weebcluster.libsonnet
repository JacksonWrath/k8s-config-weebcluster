local kube = import '1.27/main.libsonnet';

// Kubernetes API object variables
local pvc = kube.core.v1.persistentVolumeClaim;
local ingress = kube.networking.v1.ingress;
local ingressTLS = kube.networking.v1.ingressTLS;
local ingressRule = kube.networking.v1.ingressRule;
local httpIngressPath = kube.networking.v1.httpIngressPath;

{
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

  // Create a PVC with some cluster-specific defaults
  newStandardPVC(name, size, labels=null):: 
    pvc.new(name) + 
    pvc.spec.withStorageClassName(self.nvme_storage_class) +
    pvc.spec.withAccessModes(['ReadWriteOnce']) +
    pvc.spec.resources.withRequests({storage: size}) + 
    if labels != null then pvc.metadata.withLabelsMixin(labels) else {},

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
}
