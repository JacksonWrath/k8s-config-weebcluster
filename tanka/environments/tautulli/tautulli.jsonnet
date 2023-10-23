local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local kube = import '1.27/main.libsonnet';

local pvc = kube.core.v1.persistentVolumeClaim;
local container = kube.core.v1.container;
local containerPort = kube.core.v1.containerPort;
local volume = kube.core.v1.volume;
local volumeMount = kube.core.v1.volumeMount;

{
  local image = 'tautulli/tautulli:latest',
  local ingressSubdomain = 'morgiana',
  local labels = {
    app: 'tautulli',
  },

  configPVC: weebcluster.newStandardPVC('tautulli-config', '1Gi', labels),
  
  local httpContainerPort = containerPort.newNamed(8181, 'http'),
  local volumes = [
    utils.newVolumeFromPVC('config', self.configPVC),
  ],
  local volumeMounts = [
    volumeMount.new('config', '/config'),
  ],
  
  local tautulliContainer = container.new('tautulli', image) +
  container.withPorts([httpContainerPort]) +
  container.withVolumeMounts(volumeMounts),

  tautulliDeployment: utils.newSinglePodDeployment('tautulli', [tautulliContainer], labels) +
    kube.apps.v1.deployment.spec.template.spec.withVolumes(volumes),

  local servicePort = kube.core.v1.servicePort.newNamed('http', 80, httpContainerPort.name),
  tautulliService: kube.core.v1.service.new(
    name='tautulli', 
    selector=self.tautulliDeployment.spec.template.metadata.labels, 
    ports=[servicePort],
  ),

  tautulliIngress: weebcluster.newStandardIngress(
    name='tautulli', 
    subdomain=ingressSubdomain, 
    service=self.tautulliService,
    servicePort=servicePort,
  ),
}
