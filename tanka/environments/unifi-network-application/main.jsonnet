local weebcluster = import 'weebcluster.libsonnet';
local utils = import 'utils.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local k = import 'k.libsonnet';
local mongodb = import 'mongodb.libsonnet';

// k8s resources aliases
local service = k.core.v1.service;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;

local envName = 'unifiNetworkApplication';
local namespace = 'unifi-network-application';
local appName = 'unifi-network-application';

local image = weebcluster.images.unifiNetworkApplication.image;
local mongodbVersion = '7.0.12'; // Make sure the Unifi application supports the new version before upgrading
local ingressSubdomain = 'junko';
local configVolSize = '20Gi';
local externalIP = '10.2.69.20';

local labels = {
  app: appName,
};

local unifiNetworkApplicationEnv = {
  namespace: k.core.v1.namespace.new(namespace),

  local dbUsername = 'unifi', // default of linuxserver.io container
  local mongodbName = 'unifi-db', // default of linuxserver.io container
  mongodbReplicaSet: mongodb.newReplicaSet(mongodbName, mongodbVersion, dbUsername),
  mongodbRbac: mongodb.createDatabaseRole(),

  // This Secret serves two purposes; the mongodb replica set uses this to set the user password, and the
  // pod container for the network application gets that password to use in the environment variables. It's only used on
  // first run of each of these, so it could be deleted after that, but I don't bother.
  //
  // It looks like this:
  //
  // apiVersion: v1
  // kind: Secret
  // metadata:
  //   name: unifi-password
  // type: Opaque
  // stringData:
  //   password: <db-password-here>
  //   MONGO_PASS: <db-password-here>
  local firstRunSecretName = dbUsername + '-password',
  firstRunSecret: k.core.v1.secret.new(firstRunSecretName, utils.stringDataEncode(private.unifi.secretStringData)),

  stunPort:: containerPort.newNamedUDP(3478, 'stun'),
  discoveryPort:: containerPort.newNamedUDP(10001, 'discovery'),
  deviceComPort:: containerPort.newNamed(8080, 'device-com'),
  syslogPort:: containerPort.newNamedUDP(5514, 'syslog'),
  guestHttpPort:: containerPort.newNamed(8880, 'guest-http'),
  guestHttpsPort:: containerPort.newNamed(8843, 'guest-https'),

  unifiContainer:: utils.newHttpContainer(appName, image, 8443) // 8443 is the admin UI
    + container.withPortsMixin([
        self.stunPort,
        self.discoveryPort,
        self.deviceComPort,
        self.syslogPort,
        self.guestHttpPort,
        self.guestHttpsPort,
      ])
    // This env is technically only needed on first run of the container.
    + container.withEnvFrom(k.core.v1.envFromSource.secretRef.withName(firstRunSecretName)),

  unifiDeployment: utils.newSinglePodDeployment(appName, self.unifiContainer, labels),

  unifiService: utils.newServiceFromContainerPorts(appName, labels, self.unifiContainer.ports)
    + service.spec.withType('LoadBalancer')
    + service.spec.withExternalTrafficPolicy('Local')
    + service.metadata.withAnnotations({'metallb.universe.tf/loadBalancerIPs': externalIP}),

  unifiIngress: weebcluster.newStandardHttpIngress(appName, ingressSubdomain, self.unifiService),
};

weebcluster.newTankaEnv(envName, namespace, unifiNetworkApplicationEnv)
