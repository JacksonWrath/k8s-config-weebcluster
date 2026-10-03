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
      withProxyClass(proxyClass):: {
        spec+: {
          proxyClass: proxyClass,
        },
      },
    },
    proxyClass: {
      new(name):: {
        apiVersion: 'tailscale.com/v1alpha1',
        kind: 'ProxyClass',
        metadata: {
          name: name,
        },
        spec: {},
      },
      withTailscaleContainer(config):: {
        spec+: {
          statefulSet+: {
            pod+: {
              tailscaleContainer+: config,
            },
          },
        },
      },
    },
  },
}
