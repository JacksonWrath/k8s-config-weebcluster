local k = import 'k.libsonnet';
local weebcluster = import 'weebcluster.libsonnet';
local prometheusOperator = import 'prometheus-operator/prometheus-operator/prometheus-operator.libsonnet';
// lol department of redundancy department

local envName = 'prometheus-operator';
local namespace = 'prometheus-operator';

local poGithubUrl = 'https://github.com/prometheus-operator/prometheus-operator.git';
local poLibVersion = std.filter(
  function(dep) dep.source.git.remote == poGithubUrl, 
  (import '../jsonnetfile.json').dependencies
)[0].version;

local config = {
  namespace: namespace,
  version: std.strReplace(poLibVersion, 'v', ''),
  image: 'quay.io/prometheus-operator/prometheus-operator:v' + self.version,
  configReloaderImage: 'quay.io/prometheus-operator/prometheus-config-reloader:v' + self.version,
};

local poEnv = prometheusOperator(config) {
  namespace: k.core.v1.namespace.new(namespace),
};

weebcluster.newTankaEnv(envName, namespace, poEnv) + {
  spec+: {
    applyStrategy: 'server', // Because of CRDs, "last-applied-configuration" is too long with client-side apply
  }
}