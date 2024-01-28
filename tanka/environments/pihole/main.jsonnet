local kube = import '1.27/main.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';

// API object aliases
local volumeMount = kube.core.v1.volumeMount;
local container = kube.core.v1.container;
local containerPort = kube.core.v1.containerPort;
local service = kube.core.v1.service;
local servicePort = kube.core.v1.servicePort;
local ingress = kube.networking.v1.ingress;
local daemonSet = kube.apps.v1.daemonSet;
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;

local envName = 'pihole';
local namespace = 'pihole';

local piholeEnvironment = {
  local appName = 'pihole',
  local prepullImage = weebcluster.images.pihole.prepullImage,
  local piholeImage = weebcluster.images.pihole.image,
  local ingressSubdomain = 'saika',
  local configVolSize = '10Gi',
  local httpPortNumber = 80,
  local dnsPortNumber = 53,
  local dnsIp = '10.2.69.11',

  local labels = {
    app: appName,
  },

  namespace: kube.core.v1.namespace.new(namespace),

  configVolume: weebcluster.newConfigVolume(configVolSize, labels) {
    volumeMount+:: volumeMount.withMountPath('/etc/pihole'),
  },

  local dnsmasqVolName = 'dnsmasq-dot-d',
  dnsmasqVolume: {
    pvc: weebcluster.newStandardPVC(dnsmasqVolName, '10Mi', labels),
    volume:: utils.newVolumeFromPVC(dnsmasqVolName, self.pvc),
    volumeMount:: volumeMount.new(dnsmasqVolName, '/etc/dnsmasq.d'),
  },

  local piholeEnvMap = {
    TZ: 'US/Pacific',
  },
  local piholeContainer = utils.newHttpContainer(appName, piholeImage, httpPortNumber) +
    container.withEnvMap(piholeEnvMap) + 
    container.withPortsMixin(utils.generateDnsContainerPorts()) +
    container.withVolumeMounts([self.configVolume.volumeMount, self.dnsmasqVolume.volumeMount]),

  piholeDeployment: utils.newSinglePodDeployment(appName, [piholeContainer], labels) +
    podTemplateSpec.withVolumes([self.configVolume.volume, self.dnsmasqVolume.volume]),

  local selectorLabels = self.piholeDeployment.spec.template.metadata.labels,
  piholeConsoleService: utils.newHttpService(appName + '-console', selectorLabels),  
  piholeDnsService: utils.newDnsService(appName + '-dns', selectorLabels, dnsIp),

  piholeConsoleIngress: weebcluster.newStandardHttpIngress(
      name=appName + '-console',
      subdomain=ingressSubdomain,
      service=self.piholeConsoleService) +
    ingress.metadata.withAnnotationsMixin({'nginx.ingress.kubernetes.io/app-root': '/admin'}),

  ##
  # This DaemonSet exists to "pre-pull" the Pi-hole image on all nodes. I do this because my nodes are actually relying
  # on Pi-hole for their DNS; on pod restart, if the image isn't present, the node tries to pull it and fails because
  # DNS is now down. Pre-pulling the image on all nodes avoids this problem.
  #
  # When updating Pi-hole to a new image, this DaemonSet needs to be updated before updating the Pi-hole Deployment.
  # 
  # Mostly doing this because I want the DNS data of my home network in one place. Eventually I may look into pulling
  # the data into Grafana or something instead; then I may be able to run Pi-hole stateless with multiple replicas.
  ##
  local prepullInitContainer = container.new(appName + '-image', prepullImage) +
    // Override the image command to just immediately exit successfully
    container.withCommand(['sh', '-c', "'true'"]),
  // Daemonset uses the "pause" container to keep it running without consuming resources. 
  // This is because the restart policy of DaemonSets is "Always" and can't be changed
  prepullDaemonSet: daemonSet.new('prepuller', [container.new('pause', 'k8s.gcr.io/pause')], {name: 'prepuller'}) +
    daemonSet.spec.template.spec.withInitContainers([prepullInitContainer]),
};

weebcluster.newTankaEnv(envName, namespace, piholeEnvironment)
