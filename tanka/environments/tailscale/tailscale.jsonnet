local kube = import 'k.libsonnet';
local utils = import 'utils.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';

local container = kube.core.v1.container;
local deployment = kube.apps.v1.deployment;
local secret = kube.core.v1.secret;

{
  generate(input_config):: {
    local config = input_config + {
      image: 'ghcr.io/tailscale/tailscale:latest',
    },
    local labels = {
      app: config.appName,
    },

    namespace: kube.core.v1.namespace.new(config.namespace),

    // RBAC
    serviceAccount: kube.core.v1.serviceAccount.new('tailscale') +
      // Namespace needs to be added because "withSubjects()" on the roleBinding expects it
      kube.core.v1.serviceAccount.metadata.withNamespace(config.namespace),
    local rbac = kube.rbac.v1,
    local resourceRule = kube.authorization.v1.resourceRule,
    role: rbac.role.new('tailscale') +
      rbac.role.withRules([
        // Rule to create secrets
        resourceRule.withApiGroups(['']) +
        resourceRule.withResources(['secrets']) +
        resourceRule.withVerbs(['create']),
        // Rule for "tailscale-state" secret
        resourceRule.withApiGroups(['']) +
        resourceRule.withResources(['secrets']) +
        resourceRule.withResourceNames(['tailscale-state']) +
        resourceRule.withVerbs(['get', 'update', 'patch']),
      ]),
    roleBinding: rbac.roleBinding.new('tailscale') +
      rbac.roleBinding.withSubjects(rbac.subject.fromServiceAccount(self.serviceAccount)) +
      rbac.roleBinding.bindRole(self.role),

    // Resources
    tailscaleSecret: secret.new('tailscale-auth', '') + {data::''} + // Override data field to be hidden
      secret.withStringData(config.secretStringData),

    local baseEnv = {
      TS_KUBE_SECRET: 'tailscale-state',
      TS_USERSPACE: 'false',
    } + config.envMixin,
    local tailscaleSecretEnv =
      kube.core.v1.envFromSource.secretRef.withName(self.tailscaleSecret.metadata.name),

    tailscaleContainer::
      container.new('tailscale', config.image) +
      container.withEnvMap(baseEnv) +
      container.withEnvFrom(tailscaleSecretEnv) +
      container.securityContext.capabilities.withAdd('NET_ADMIN'),

    tailscaleDeployment:
      local templateSpec = deployment.spec.template.spec;
      utils.newSinglePodDeployment(config.appName, [self.tailscaleContainer], labels) +
      templateSpec.withHostname(config.tailscaleDeviceHostname) +
      templateSpec.withServiceAccountName(self.serviceAccount.metadata.name),
  },
}
