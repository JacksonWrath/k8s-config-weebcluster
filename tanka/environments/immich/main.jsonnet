local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';
local k = import 'k.libsonnet';
local utils = import 'utils.libsonnet';
local cnpg = import 'cnpg/main.libsonnet';

// API aliases
local container = k.core.v1.container;
local podTemplateSpec = k.apps.v1.deployment.spec.template.spec;
local pgCluster = cnpg.postgresql.v1.cluster;

local envName = 'immich';
local namespace = 'immich';

local appConfig = weebcluster.defaultAppConfig + {
  appName: 'immich',
  image: weebcluster.images.immich.image,
  httpPortNumber: 2283,
  mlPort: 3003,
  redisPort: 6379,
  configVolSize: '10Gi',
  subdomain: 'photos',
  mlCacheSize: '100Gi', // depends on how much you play with different models I think
  envMap: {
    IMMICH_PORT: "" + appConfig.httpPortNumber,
    REDIS_PORT: "" + appConfig.redisPort,
    DB_HOSTNAME: 'postgres-rw.%s' % namespace,
    DB_USERNAME: private.immich.postgres.username,
    DB_PASSWORD: private.immich.postgres.password,
    REDIS_HOSTNAME: 'redis.%s' % namespace,
  },
};
local labels = {
  app: appConfig.appName,
};

local pgConfig = {
  clusterName: 'postgres',
  image: weebcluster.images.immichPostgres.image,
  volSize: '100Gi', // by all accounts this should be super overkill
  dbName: 'immich',
  parameters: {
    // These come from Immich's docker-compose
    search_path: '"$user", public, vectors',
    // Discussion on this PR outlines most of the perf tuning: https://github.com/immich-app/immich/pull/9384
    shared_buffers: '512MB',
    max_wal_size: '2GB',
    wal_compression: 'zstd',
    // logging_collector is managed by the operator
    // shared_preload_libraries is managed by the operator
  },
  sharedLibraries: [
    'vectors.so', // Note that this requires an image with it built in
  ],
};

local immichEnv = {
  namespace: k.core.v1.namespace.new(namespace),

  redis: {
    local redisContainerPort = k.core.v1.containerPort.newNamed(appConfig.redisPort, 'redis'),
    local redisContainer = container.new('redis-container', weebcluster.images.redis.image) +
      container.withPorts(redisContainerPort),
    local redisSelectors = labels + { 'immich-component': 'redis'},
    deployment: utils.newSinglePodDeployment('redis', [redisContainer], redisSelectors),
    service: utils.newServiceFromContainerPorts('redis', redisSelectors, [redisContainerPort])
  },

  postgresEnvSecret: k.core.v1.secret.new('postgres-user', utils.stringDataEncode(private.immich.postgres)),
  postgres: pgCluster.new(pgConfig.clusterName) +
    pgCluster.spec.withImageName(pgConfig.image) +
    pgCluster.spec.withInstances(1) +
    pgCluster.spec.withEnableSuperuserAccess(true) + // immich's support for non-superuser isn't great. There's loads of GitHub issues where the root cause was "bug when not using the superuser"
    pgCluster.spec.superuserSecret.withName(self.postgresEnvSecret.metadata.name) +
    pgCluster.spec.storage.withSize(pgConfig.volSize) +
    pgCluster.spec.postgresql.withShared_preload_libraries(pgConfig.sharedLibraries) +
    pgCluster.spec.postgresql.withParameters(pgConfig.parameters) +
    pgCluster.spec.bootstrap.initdb.withDatabase(pgConfig.dbName) +
    pgCluster.spec.bootstrap.initdb.withOwner('postgres') +
    pgCluster.spec.bootstrap.initdb.secret.withName(self.postgresEnvSecret.metadata.name) +
    pgCluster.spec.bootstrap.initdb.withDataChecksums(true),

  machineLearning: {
    cacheVolume: {
      pvc: utils.newStandardPVC('immich-ml-cache', appConfig.mlCacheSize, weebcluster.defaultStorageClass, labels),
      volume:: utils.newVolumeFromPVC('ml-cache', self.pvc),
      volumeMount:: k.core.v1.volumeMount.new('ml-cache', '/cache'),
    },
    local mlContainerPort = k.core.v1.containerPort.newNamed(appConfig.mlPort, 'ml-port'),
    local mlContainer = container.new('ml-container', weebcluster.images.immichML.image) +
      container.withVolumeMounts(self.cacheVolume.volumeMount) +
      container.withEnvMap(appConfig.envMap) +
      container.withPorts(mlContainerPort),
    local mlSelectors = labels + { 'immich-component': 'ml'},
    mlDeployment: utils.newSinglePodDeployment('immich-machine-learning', [mlContainer], mlSelectors) +
      k.apps.v1.deployment.spec.template.spec.withVolumes(self.cacheVolume.volume),
    service: utils.newServiceFromContainerPorts('immich-machine-learning', mlSelectors, [mlContainerPort])
  },

  immich: {
    local primaryNfs = homelab.nfs.currentPrimary,
    local nfsVolume = utils.newNfsVolume('immich-nfs', primaryNfs.server, primaryNfs.shares.immich),
    app: utils.newStandardApp(appConfig) + {
      container+::
        container.withEnvMap(appConfig.envMap) +
        container.withVolumeMountsMixin(k.core.v1.volumeMount.new('immich-nfs', '/usr/src/app/upload')),
      deployment+:
        podTemplateSpec.withVolumesMixin(nfsVolume) +
        podTemplateSpec.securityContext.withRunAsUser(1000) +
        podTemplateSpec.securityContext.withRunAsGroup(1000) +
        podTemplateSpec.securityContext.withFsGroupChangePolicy('OnRootMismatch'),
    },
  },
};

weebcluster.newTankaEnv(envName, namespace, immichEnv)