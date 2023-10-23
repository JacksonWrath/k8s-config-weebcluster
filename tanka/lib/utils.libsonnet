local kube = import '1.27/main.libsonnet';

// API objects
local volume = kube.core.v1.volume;
local deployment = kube.apps.v1.deployment;

{
  newVolumeFromPVC(name, persistentVolumeClaim)::
    volume.withName(name) + 
    volume.persistentVolumeClaim.withClaimName(persistentVolumeClaim.metadata.name),

  // Generate a standard single-replica deployment
  newSinglePodDeployment(name, containers, labels)::
    deployment.new(name, 1, containers, labels) +
    deployment.metadata.withLabels(labels) + 
    deployment.spec.strategy.withType('Recreate'),
}