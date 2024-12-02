{
  'cert-manager': {
    name: 'cert-manager',
    repo: 'https://charts.jetstack.io',
    version: 'v1.16.1',
  },
  etcd: {
    name: 'etcd',
    oci: 'oci://registry-1.docker.io/bitnamicharts/etcd',
    version: '10.5.2',
  },
  metallb: {
    name: 'metallb',
    repo: 'https://metallb.github.io/metallb',
    version: '0.14.8',
  },
  'mongodb-operator': {
    name: 'community-operator',
    repo: 'https://mongodb.github.io/helm-charts',
    version: '0.11.0',
  },
  gitea: {
    name: 'gitea',
    repo: 'https://dl.gitea.com/charts',
    version: '9.5.1',
  },
  'ingress-nginx': {
    name: 'ingress-nginx',
    repo: 'https://kubernetes.github.io/ingress-nginx',
    version: '4.11.3',
  },
  'rook-ceph': {
    name: 'rook-ceph',
    repo: 'https://charts.rook.io/release',
    version: 'v1.15.6',
  },
}
