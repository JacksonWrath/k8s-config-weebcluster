local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local k = import 'k.libsonnet';

// API object aliases
local podTemplateSpec = k.apps.v1.deployment.spec.template.spec;
local container = k.core.v1.container;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;

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
  namespace: k.core.v1.namespace.new(namespace),
  local primaryNfs = homelab.nfs.currentPrimary,

  // Gluetun wireguard secret
  wireguardSecret: k.core.v1.secret.new(
    name='wireguard-config',
    data=utils.stringDataEncode({'wg0.conf': private.wireguard.gluetun_secret_stringData}),
  ),

  // Gluetun auth config secret
  authConfigSecret: k.core.v1.secret.new(
    name='auth-config',
    data=utils.stringDataEncode({'config.toml': private.gluetun.qbt.authConfig}),
  ),

  // Gluetun doesn't have a way to allow additional inbound subnets, and Calico is breaking the
  // LAN subnet detection because it sets the default route to 169.254.1.1
  // Thankfully Gluetun does provide a way to specify additional iptables rules.
  iptablesConfigMap: k.core.v1.configMap.new('iptables-rules', {
    'post-rules.txt': |||
      iptables -A INPUT -i eth0 -s %(podCidr)s -j ACCEPT
      iptables -A OUTPUT -o eth0 -d %(podCidr)s -j ACCEPT
    ||| % weebcluster.clusterCidrs,
  }),

  // Additional volumes on deployment
  local additionalVolumes = [
    utils.newSecretVolume(self.wireguardSecret.metadata.name),
    utils.newSecretVolume(self.authConfigSecret.metadata.name),
    k.core.v1.volume.fromConfigMap(self.iptablesConfigMap.metadata.name, self.iptablesConfigMap.metadata.name),
    utils.newNfsVolume(
      name='qbittorrent-nfs',
      server=primaryNfs.server,
      path=primaryNfs.shares.media + '/qbittorrent',
    ),
  ],

  // Gluetun container
  local gluetunContainer = container.new('gluetun', weebcluster.images.gluetun.image) +
    container.securityContext.capabilities.withAdd(['NET_ADMIN']) +
     // Setting "restartPolicy: Always" on an initContainer identifies it as a sidecar; beta feature in k8s 1.29
    container.withRestartPolicy("Always") +
    container.withEnvMap({
      VPN_SERVICE_PROVIDER: 'custom',
      VPN_TYPE: 'wireguard',
      VPN_PORT_FORWARDING: 'on',
      VPN_PORT_FORWARDING_PROVIDER: 'protonvpn',
      HTTP_CONTROL_SERVER_LOG: 'off',
    }) +
    container.withVolumeMounts([
      volumeMount.new(self.wireguardSecret.metadata.name, '/gluetun/wireguard'),
      volumeMount.new(self.authConfigSecret.metadata.name, '/gluetun/auth'),
      volumeMount.new(self.iptablesConfigMap.metadata.name, '/iptables'),
    ]),

  // Port-forwarding sync container
  local portUpdaterContainer = container.new('port-updater', weebcluster.images.port_updater.image) +
    container.withEnvMap({
      QBT_USERNAME: private.qbittorrent.username,
      QBT_PASSWORD: private.qbittorrent.password,
    }),

  qbittorrentApp: weebcluster.newStandardApp(appConfig) {
    local envMap = {PUID: '1000', PGID: '1000'},
    container+::
      container.withEnvMap(envMap) +
      container.withVolumeMountsMixin([volumeMount.new('qbittorrent-nfs', '/data/qbittorrent')]),
    deployment+: 
      k.apps.v1.deployment.spec.selector.withMatchLabels({app: 'qbittorrent'}) +
      podTemplateSpec.withInitContainersMixin([gluetunContainer]) +
      podTemplateSpec.withContainersMixin([portUpdaterContainer]) +
      podTemplateSpec.withVolumesMixin(additionalVolumes),
  },
};

weebcluster.newTankaEnv(envName, namespace, qbittorrentEnvironment)