local kube = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local homelab = import 'homelab.libsonnet';
local backup = import 'jsonnet/backup.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';

local envName = 'restic-k8s-backup';
local namespace = 'restic-k8s-backup';

local primaryNfs = homelab.nfs.currentPrimary;

local backupConfig = {
  namespace: namespace,
  nfsServer: primaryNfs.server,
  nfsPath: primaryNfs.shares.backups,
  nfsSubpath: '/restic-k8s-backup',
  snapshotClass: if std.objectHas(weebcluster, 'snapshotClass') then weebcluster.snapshotClass else 'csi-hostpath-snapclass',
  clusterName: weebcluster.name,
  image: 'ghcr.io/jacksonwrath/restic-k8s-backup@sha256:6453850ed9b7c2f2fd631f3fe52f853be15aafdffc055e76f8672ae95874c3a8',
  workerActiveDeadline: '6h',
  maxWorkers: 4,
};

local backupEnvironment = {
  namespace: kube.core.v1.namespace.new(namespace),

  secret: kube.core.v1.secret.new('restic-repository-password', {}) 
    + kube.core.v1.secret.withStringData({
    password: private.resticBackups.repoPassword,
  }),

  orchestrator: backup.backupOrchestrator(backupConfig),
};

weebcluster.newTankaEnv(envName, namespace, backupEnvironment)
