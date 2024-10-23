// Some helper functions for creating resources using the mongodb community operator

local k = import 'k.libsonnet';

local role = k.rbac.v1.role;
local roleBinding = k.rbac.v1.roleBinding;
local resourceRule = k.authorization.v1.resourceRule;

{
  // Note, expects secret name "<username>-password" to exist with the password to use when first created
  newReplicaSet(name, version, username):: {
    apiVersion: 'mongodbcommunity.mongodb.com/v1',
    kind: 'MongoDBCommunity',
    metadata: {
      name: name,
    },
    spec: {
      members: 3,
      type: 'ReplicaSet',
      version: version,
      security: {
        authentication: {
          modes: ['SCRAM']
        },
      },
      users: [
        {
          name: username,
          db: 'admin',
          passwordSecretRef: {
            name: username + '-password',
          },
          roles: [
            {
              name: 'clusterAdmin',
              db: 'admin',
            },
            {
              name: 'userAdminAnyDatabase',
              db: 'admin',
            }
          ],
          scramCredentialsSecretName: 'my-scram',
        },
      ],
      additionalMongodConfig: {
        'storage.wiredTiger.engineConfig.journalCompressor': 'zlib',
      },
    },
  },

  // The operator doesn't create these in the namespaces it watches, but they are required, so you have to create them
  // yourself in each namespace.
  createDatabaseRole():: {
    local name = 'mongodb-database',
    local roleRules = [
      resourceRule.withApiGroups([''])
      + resourceRule.withResources(['secrets'])
      + resourceRule.withVerbs(['get']),
      resourceRule.withApiGroups([''])
      + resourceRule.withResources(['pods'])
      + resourceRule.withVerbs(['patch', 'delete', 'get']),
    ],
    local subject = k.rbac.v1.subject.withName(name)
      + k.rbac.v1.subject.withKind('ServiceAccount'),
    serviceAccount: k.core.v1.serviceAccount.new(name),
    role: role.new(name)
      + role.withRules(roleRules),
    roleBinding: roleBinding.new(name)
      + roleBinding.withSubjects([subject])
      + roleBinding.bindRole(self.role),
  }
}