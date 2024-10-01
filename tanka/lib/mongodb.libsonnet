// Some helper functions for creating resources using the mongodb community operator

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
      addtionalMongodConfig: {
        'storage.wiredTiger.engineConfig.journalCompressor': 'zlib',
      },
    },
  },
}