// This library is a set of agnostic utility functions that work without knowledge of the specific k8s environment.

local kube = import '1.27/main.libsonnet';

// API objects
local volume = kube.core.v1.volume;
local deployment = kube.apps.v1.deployment;
local service = kube.core.v1.service;

{
  // Generate a Container with an exposed port named 'http'
  newHttpContainer(name, image, portNumber)::
    local httpContainerPort = kube.core.v1.containerPort.newNamed(portNumber, 'http');
    kube.core.v1.container.new(name, image) +
    kube.core.v1.container.withPorts([httpContainerPort]),

  // Generate a Volume object from a PVC
  newVolumeFromPVC(name, persistentVolumeClaim)::
    volume.withName(name) + 
    volume.persistentVolumeClaim.withClaimName(persistentVolumeClaim.metadata.name),

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

}