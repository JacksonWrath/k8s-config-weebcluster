local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local k = import 'k.libsonnet';
local mongodb = import 'mongodb.libsonnet';

local envName = 'unifiNetworkController';
local namespace = 'unifi-network-controller';
local appName = 'unifi-network-controller';

local image = weebcluster.images.unifiNetworkController.image;
local mongodbVersion = '7.0.12'; // Make sure the Unifi controller supports the new version before upgrading
local ingressSubdomain = 'junko';
local configVolSize = '20Gi';

local labels = {
  app: appName,
};

local unifiNetworkControllerEnv = {
  namespace: k.core.v1.namespace.new(namespace),

  local dbUsername = 'unifi', // default of linuxserver.io container
  local mongodbName = 'unifi-db', // default of linuxserver.io container
  mongodbReplicaSet: mongodb.newReplicaSet(mongodbName, mongodbVersion, dbUsername),

  local containerPort = k.core.v1.containerPort,
  stunPort:: containerPort.newNamedUDP(3478, 'stun'),
  discoveryPort:: containerPort.newNamedUDP(10001, 'discovery'),
  deviceComPort:: containerPort.newNamed(8080, 'device-com'),
  syslogPort:: containerPort.newNamedUDP(5514, 'syslog'),
  guestHttpPort:: containerPort.newNamed(8880, 'guest-http'),
  guestHttpsPort:: containerPort.newNamed(8843, 'guest-https'),

  local container = k.core.v1.container,
  unifiContainer:: utils.newHttpContainer(appName, image, 8443) // 8443 is the admin UI
    + container.withPortsMixin([
        self.stunPort,
        self.discoveryPort,
        self.deviceComPort,
        self.syslogPort,
        self.guestHttpPort,
        self.guestHttpsPort,
      ])
    // This is only needed on first run of the container. Secret format is at the bottom.
    + container.withEnvFrom(k.core.v1.envFromSource.secretRef.withName('unifi-password')),

  unifiDeployment: utils.newSinglePodDeployment(appName, self.unifiContainer, labels),
};

weebcluster.newTankaEnv(envName, namespace, unifiNetworkControllerEnv)

// Manually created secret on first deployment
//
// The manually created Secret serves two purposes; the mongodb replica set uses this to set the user password, and the
// pod container for the network controller gets the password to use in the environment variables. It's only used on
// first run of each of these; I deleted it after that.
//
// It looks like this:
//
// apiVersion: v1
// kind: Secret
// metadata:
//   name: unifi-password
// type: Opaque
// stringData:
//   password: <password-here>
//   MONGO_PASS: <password-here>