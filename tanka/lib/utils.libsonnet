// This library is a set of agnostic utility functions that work without knowledge of the specific k8s environment.

local kube = import 'k.libsonnet';

// API objects
local volume = kube.core.v1.volume;
local deployment = kube.apps.v1.deployment;
local service = kube.core.v1.service;
local persistentVolume = kube.core.v1.persistentVolume;
local persistentVolumeClaim = kube.core.v1.persistentVolumeClaim;

{
  // Some generic constants
  nginxIngressAllowAll: {'nginx.ingress.kubernetes.io/whitelist-source-range': '0.0.0.0/0'},

  // Generate a Container with an exposed port named 'http'
  newHttpContainer(name, image, portNumber)::
    local httpContainerPort = kube.core.v1.containerPort.newNamed(portNumber, 'http');
    kube.core.v1.container.new(name, image) +
    kube.core.v1.container.withPorts([httpContainerPort]),

  // Generate a Volume object from a PVC
  newVolumeFromPVC(name, persistentVolumeClaim)::
    volume.withName(name) + 
    volume.persistentVolumeClaim.withClaimName(persistentVolumeClaim.metadata.name),

  newSecretVolume(secretName, keyName, path)::
    volume.withName(secretName) + 
    volume.secret.withSecretName(secretName) +
    volume.secret.withItems([{key: keyName, path: path}]),
  
  newNfsVolume(name, server, path, readOnly=false)::
    volume.withName(name) + 
    volume.nfs.withServer(server) +
    volume.nfs.withPath(path) +
    if readOnly then volume.nfs.withReadOnly(readOnly) else {},

  // Generate a standard single-replica deployment
  newSinglePodDeployment(name, containers, labels)::
    deployment.new(name, 1, containers, labels) +
    deployment.metadata.withLabels(labels) + 
    deployment.spec.strategy.withType('Recreate'),

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

  // Creates a new Container with port 53 exposed on TCP and UDP
  newDnsContainer(name, image):: 
    kube.core.v1.container.new(name, image) +
    kube.core.v1.container.withPorts(self.generateDnsContainerPorts()),

  // Generates container ports exposing port 53 on TCP and UDP
  generateDnsContainerPorts():: [
    kube.core.v1.containerPort.newNamed(53, 'dns-tcp'),
    kube.core.v1.containerPort.newNamedUDP(53, 'dns-udp'),
  ],

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

  stringDataEncode(stringData):: {
    [field.key]: std.base64(field.value)
    for field in std.objectKeysValues(stringData)
  },
}
