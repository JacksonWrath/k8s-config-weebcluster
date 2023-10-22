local kube = import '1.27/main.libsonnet';
local private = import 'libsonnet-secrets/rewt.libsonnet';

local container = kube.core.v1.container;
local deployment = kube.apps.v1.deployment;
local secret = kube.core.v1.secret;

{
  _config:: {
    // Container image for updates
    image: 'ghcr.io/tailscale/tailscale:latest',
    app_name:'tailscale-exit-node',
    envVars: {
      TS_KUBE_SECRET: 'tailscale-state',
      TS_EXTRA_ARGS: '--advertise-exit-node',
      TS_ROUTES: '10.0.0.0/8,172.16.0.0/12,192.168.0.0/16',
    },
    tailscale_device_hostname: 'weebcluster-exit-node',
  },

  labels:: {
    app: $._config.app_name,
  },

  // RBAC
  service_account: kube.core.v1.serviceAccount.new('tailscale') +
    kube.core.v1.serviceAccount.metadata.withNamespace($._config.namespace),
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
      resourceRule.withVerbs(['get', 'update', 'patch'])
    ]),
  role_binding: rbac.roleBinding.new('tailscale') + 
    rbac.roleBinding.withSubjects(rbac.subject.fromServiceAccount($.service_account)) +
    rbac.roleBinding.bindRole($.role),


  // Resources
  local ts_secret_name = 'tailscale-auth',
  ts_secret: secret.new(ts_secret_name, '') + {data::''} + // Override data field to be hidden
    secret.withStringData(private.tailscale.secret_stringData),
  ts_secret_env:: 
    kube.core.v1.envVar.fromSecretRef('TS_AUTH_KEY', self.ts_secret.metadata.name, 'TS_AUTHKEY'),

  ts_container:: 
    container.withName('tailscale') +
    container.withImage($._config.image) +
    container.withEnvMap($._config.envVars) +
    container.withEnvMixin([self.ts_secret_env]) +
    container.securityContext.capabilities.withAdd('NET_ADMIN'),
  
  ts_deployment: 
    deployment.new($._config.app_name, 1, [$.ts_container], $.labels) +
    deployment.spec.template.spec.withHostname($._config.tailscale_device_hostname) +
    deployment.spec.template.spec.withServiceAccountName(self.service_account.metadata.name) + 
    deployment.spec.strategy.withType('Recreate'),
}