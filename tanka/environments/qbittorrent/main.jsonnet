local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local kube = import 'k.libsonnet';

// API object aliases
local podTemplateSpec = kube.apps.v1.deployment.spec.template.spec;
local container = kube.core.v1.container;
local volume = kube.core.v1.volume;
local volumeMount = kube.core.v1.volumeMount;


local envName = 'qbittorrent';
local namespace = 'qbittorrent';

local appConfig = {
  appName: 'qbittorrent',
  image: weebcluster.images.qbittorrent.image,
  subdomain: 'vash',
  configVolSize: '1Gi',
  httpPortNumber: 8080,
};

local qbittorrentEnvironment = {
  local wgImage = 'ghcr.io/k8s-at-home/wireguard:v1.0.20210914',
  local primaryNfs = homelab.nfs.currentPrimary,

  // Wireguard container
  local wireguardContainer = container.new('wireguard', wgImage) +
    container.securityContext.capabilities.withAdd(['NET_ADMIN', 'SYS_MODULE']) +
    container.withVolumeMounts([
      volumeMount.new('wireguard-wg0-secret', '/etc/wireguard/wg0.conf') + volumeMount.withSubPath('wg0.conf')
    ]) +
    container.withEnvMap({
      IPTABLES_BACKEND: 'legacy',
      KILLSWITCH: 'true',
      KILLSWITCH_EXCLUDEDNETWORKS_IPV4: '10.69.20.0/22',
    }),

  // Wireguard secret
  wireguardSecret: kube.core.v1.secret.new('wireguard-wg0-secret', '') + {data::''} +
    kube.core.v1.secret.withStringData({'wg0_ipv4.conf': private.wireguard.secret_stringData}),

  // Additional volumes on deployment
  local additionalVolumes = [
    utils.newSecretVolume(
      secretName='wireguard-wg0-secret',
      keyName='wg0_ipv4.conf',
      path='wg0.conf'
    ),
    utils.newNfsVolume(
      name='qbittorrent-nfs',
      server=primaryNfs.server,
      path=primaryNfs.shares.media + '/qbittorrent',
    ),
  ],

  qbittorrentApp: weebcluster.newStandardApp(appConfig) {
    local sysctls = [{name: 'net.ipv4.conf.all.src_valid_mark', value: '1'}],
    local envMap = {PUID: '1000', PGID: '1000'},
    container+::
      container.withEnvMap(envMap) +
      container.withVolumeMountsMixin([volumeMount.new('qbittorrent-nfs', '/data/qbittorrent')]),
    deployment+: 
      kube.apps.v1.deployment.spec.selector.withMatchLabels({app: 'qbittorrent'}) +
      podTemplateSpec.securityContext.withSysctls(sysctls) +
      podTemplateSpec.withContainersMixin([wireguardContainer]) +
      podTemplateSpec.withVolumesMixin(additionalVolumes),
  },
};

weebcluster.newTankaEnv(envName, namespace, qbittorrentEnvironment)