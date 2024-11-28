// This library is a set of agnostic utility functions that work without knowledge of the specific k8s environment.

local kube = import 'k.libsonnet';

// Kubernetes API object variables
local pvc = kube.core.v1.persistentVolumeClaim;
local volume = kube.core.v1.volume;
local deployment = kube.apps.v1.deployment;
local service = kube.core.v1.service;
local ingress = kube.networking.v1.ingress;
local ingressTLS = kube.networking.v1.ingressTLS;
local ingressRule = kube.networking.v1.ingressRule;
local httpIngressPath = kube.networking.v1.httpIngressPath;
local persistentVolume = kube.core.v1.persistentVolume;
local persistentVolumeClaim = kube.core.v1.persistentVolumeClaim;

{
  local utils = self,

  // Some generic constants
  nginxIngressAllowAll: {'nginx.ingress.kubernetes.io/whitelist-source-range': '0.0.0.0/0'},
  certIssuer: {
    letsencrypt: 'letsencrypt',
    letsencryptStaging: 'letsencrypt-staging',
  },

  /***********************
    App Config Object
   ***********************/
  
  // This is the input format to several functions in this library.
  appConfig:: {
    // General app configs
    appName: error 'must define appName',
    image: error 'must define image',
    configVolSize: error 'must define configVolSize',
    configVolStorageClass: error 'must define configVolStorageClass',
    httpPortNumber: error 'must define httpPortNumber',
    
    // Ingress-related configs
    ingressName: self.appName,
    subdomain: error 'must define subdomain',
    primaryDomains: error 'must define primaryDomains',
    ingressClass: error 'must define ingressClass',
    pathPrefix: '/',
    tlsEnabled: true,
    useStagingCertIssuer: false,

    additionalLabels: {},
  },

  /***********************
    Volume functions
   ***********************/

  // Generate objects necessary for a standard "config" volume
  newConfigVolume(size, storageClass, labels):: {
    local volumeName = labels.app + '-config',
    configPVC: utils.newStandardPVC(volumeName, size, storageClass, labels),
    volume:: utils.newVolumeFromPVC('config', self.configPVC),
    volumeMount:: kube.core.v1.volumeMount.new('config', '/config'),
  },

  // Create a PVC with some cluster-specific defaults
  newStandardPVC(name, size, storageClass, labels=null):: 
    pvc.new(name) + 
    pvc.spec.withStorageClassName(storageClass) +
    pvc.spec.withAccessModes(['ReadWriteOnce']) +
    pvc.spec.resources.withRequests({storage: size}) + 
    if labels != null then pvc.metadata.withLabelsMixin(labels) else {},

  // Generate a Volume object from a PVC
  newVolumeFromPVC(name, persistentVolumeClaim)::
    volume.withName(name) + 
    volume.persistentVolumeClaim.withClaimName(persistentVolumeClaim.metadata.name),

  // Generate a Volume object that's populated from a Secret
  newSecretVolume(secretName, keyName=null, path=null)::
    volume.withName(secretName) + 
    volume.secret.withSecretName(secretName) +
    if keyName != null && path != null then volume.secret.withItems([{key: keyName, path: path}]) else {},
  
  // Generate a Volume object for an NFS server
  newNfsVolume(name, server, path, readOnly=false)::
    volume.withName(name) + 
    volume.nfs.withServer(server) +
    volume.nfs.withPath(path) +
    if readOnly then volume.nfs.withReadOnly(readOnly) else {},

  /***********************
    Deployment / App functions
   ***********************/

  // Typical app setup that I use
  newStandardApp(appConfig):: {
    local appName = appConfig.appName,
    local labels = {
      app: appName,
    } + appConfig.additionalLabels,

    configVolume: utils.newConfigVolume(appConfig.configVolSize, appConfig.configVolStorageClass, labels),
    
    container:: utils.newHttpContainer(appName, appConfig.image, appConfig.httpPortNumber) +
    kube.core.v1.container.withVolumeMounts([self.configVolume.volumeMount]),

    deployment: utils.newSinglePodDeployment(appName, [self.container], labels) +
      kube.apps.v1.deployment.spec.template.spec.withVolumes([self.configVolume.volume]),

    service: utils.newHttpService(appName, self.deployment.spec.template.metadata.labels),

    ingress: utils.newStandardHttpIngress(self.service, appConfig),
  },

  // Generate a standard single-replica deployment
  newSinglePodDeployment(name, containers, labels)::
    deployment.new(name, 1, containers, labels) +
    deployment.metadata.withLabels(labels) + 
    deployment.spec.strategy.withType('Recreate'),

  /***********************
    Service functions
   ***********************/

  // Generate a standard HTTP service pointed at the given selector labels
  // Assumes the container port is named 'http'
  newHttpService(name, selectorLabels)::
    local servicePort = kube.core.v1.servicePort.newNamed('http', 80, 'http');
    service.new(
      name=name, 
      selector=selectorLabels, 
      ports=[servicePort],
    ),

  newServiceFromContainerPorts(name, selectorLabels, containerPorts)::
    service.new(
      name=name,
      selector=selectorLabels,
      ports=[
        kube.core.v1.servicePort.newNamed(port.name, port.containerPort, port.name)
          + kube.core.v1.servicePort.withProtocol(if std.objectHas(port, 'protocol') then port.protocol else 'TCP')
        for port in containerPorts
      ],
    ),

  // Creates a new LoadBalancer Service to point at a workload with a DNS container created by "newDnsContainer()"
  // Sets externalTrafficPolicy to Local, and requests the provided IP from MetalLB (via annotation)
  newDnsService(name, selectorLabels, loadBalancerIP):: 
    local servicePorts = [
      kube.core.v1.servicePort.newNamed('dns-tcp', 53, 'dns-tcp'),
      kube.core.v1.servicePort.newNamed('dns-udp', 53, 'dns-udp') + kube.core.v1.servicePort.withProtocol('UDP'),
    ];
    service.new(name, selectorLabels, servicePorts) +
    service.spec.withType('LoadBalancer') +
    service.spec.withExternalTrafficPolicy('Local') +
    service.metadata.withAnnotations({'metallb.universe.tf/loadBalancerIPs': loadBalancerIP}),

  /***********************
    Ingress functions
   ***********************/
  
  // Create a typical Ingress
  local defaultIngressAnnotations = {
    // No default annotations currently
  },
  newStandardIngress(service, servicePort, appConfig):: 
    local SANs = [appConfig.subdomain + '.' + domain for domain in appConfig.primaryDomains];
    local backendService = 
      httpIngressPath.backend.service.withName(service.metadata.name) +
      httpIngressPath.backend.service.port.withName(servicePort.name);
    local path = httpIngressPath.withPath(appConfig.pathPrefix) + httpIngressPath.withPathType('Prefix') + backendService;
    local rules = [ingressRule.withHost(fqdn) + ingressRule.http.withPaths([path]) for fqdn in SANs];

    ingress.new(appConfig.ingressName) +
    ingress.metadata.withAnnotations(defaultIngressAnnotations) +
    ingress.spec.withIngressClassName(appConfig.ingressClass) + 
    ingress.spec.withRules(rules) +
    (
      if appConfig.tlsEnabled then 
        local tlsSecretName = appConfig.ingressName + '-tls';
        local tls = ingressTLS.withHosts(SANs) + ingressTLS.withSecretName(tlsSecretName);
        ingress.metadata.withAnnotationsMixin(
          { 'cert-manager.io/cluster-issuer': if appConfig.useStagingCertIssuer then utils.certIssuer.letsencryptStaging else utils.certIssuer.letsencrypt }
        ) +
        ingress.spec.withTls(tls)
      else
        {}
    ) + {
      SANs:: SANs, // Added so the computed SANs can be accessed by caller, if needed.
    },

  // Create a typical Ingress pointed at the 'http' port of a given service
  newStandardHttpIngress(service, appConfig)::
    local servicePort = kube.core.v1.servicePort.withName('http');
    self.newStandardIngress(service, servicePort, appConfig),

  /***********************
    Container functions
   ***********************/

  // Generate a Container with an exposed port named 'http'
  newHttpContainer(name, image, portNumber)::
    local httpContainerPort = kube.core.v1.containerPort.newNamed(portNumber, 'http');
    kube.core.v1.container.new(name, image) +
    kube.core.v1.container.withPorts([httpContainerPort]),

  // Creates a new Container with port 53 exposed on TCP and UDP
  newDnsContainer(name, image):: 
    kube.core.v1.container.new(name, image) +
    kube.core.v1.container.withPorts(self.generateDnsContainerPorts()),

  // Generates container ports exposing port 53 on TCP and UDP
  generateDnsContainerPorts():: [
    kube.core.v1.containerPort.newNamed(53, 'dns-tcp'),
    kube.core.v1.containerPort.newNamedUDP(53, 'dns-udp'),
  ],

  /***********************
    NFS-related functions
   ***********************/

  newNfsPV(name, mountOptions=[], server, path, size)::
    persistentVolume.new(name) +
      persistentVolume.spec.withStorageClassName('nfs') +
      persistentVolume.spec.withAccessModes('ReadWriteMany') +
      persistentVolume.spec.withMountOptions(mountOptions) +
      persistentVolume.spec.withCapacity({storage: size}) +
      persistentVolume.spec.nfs.withServer(server) +
      persistentVolume.spec.nfs.withPath(path),
    
  newNfsPVCFromPV(name, pv)::
    persistentVolumeClaim.new(name) +
      persistentVolumeClaim.spec.withVolumeName(pv.metadata.name) +
      persistentVolumeClaim.spec.withStorageClassName('nfs') +
      persistentVolumeClaim.spec.withAccessModes(['ReadWriteMany']) +
      persistentVolumeClaim.spec.resources.withRequests(pv.spec.capacity),

  // Other utilities

  // Inline Tanka environment
  newTankaEnv(apiServer, envName, namespace, data):: {
    apiVersion: 'tanka.dev/v1alpha1',
    kind: 'Environment',
    metadata: {
      name: envName,
    },
    spec: {
      apiServer: apiServer,
      namespace: namespace,
      injectLabels: true, // This allows running 'tk prune' to clean up removed resources.
      applyStrategy: 'server',
    },
    data: data,
  },

  // Takes an object of exclusively string fields and encodes each field's value in base64
  stringDataEncode(stringData):: {
    [field.key]: std.base64(field.value)
    for field in std.objectKeysValues(stringData)
  },
}
