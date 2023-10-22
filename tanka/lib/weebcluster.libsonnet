{
    newTankaEnv(name, namespace, data):: {
      apiVersion: 'tanka.dev/v1alpha1',
      kind: 'Environment',
      metadata: {
        name: name,
      },
      spec: {
        apiServer: 'https://aomine.bukkake.cafe:6443',
        namespace: namespace,
      },
      data: data,
    },

    // Cluster constants
    nvme_storage_class: 'nvme-rook-ceph',
}
