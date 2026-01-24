{
  v1alpha1: {
    connector: {
      new(name, hostname):: {
        apiVersion: 'tailscale.com/v1alpha1',
        kind: 'Connector',
        metadata: {
          name: name,
        },
        spec: {
          hostname: hostname,
        },
      },
      withTags(tags):: {
        spec+: {
          tags: tags,
        },
      },
      withRoutes(routes):: {
        spec+: {
          subnetRouter: {
            advertiseRoutes: routes,
          },
        },
      },
      withExitNode(enabled):: {
        spec+: {
          exitNode: enabled,
        },
      },
    },
  },
}
