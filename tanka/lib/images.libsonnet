{
  images: {
    node_exporter: {
      followTag: 'latest',
      image: 'prom/node-exporter:v1.8.1',
    },
    graphite_exporter: {
      followTag: 'latest',
      image: 'prom/graphite-exporter:v0.15.1',
    },
    kube_state_metrics: {
      followTag: '2.12.0',
      image: 'bitnami/kube-state-metrics:2.12.0-debian-12-r10',
    },
    pihole: {
      followTag: 'latest',
      image: 'pihole/pihole:2024.05.0',
      prepullImage: 'pihole/pihole:2024.05.0',
    },
    plex: {
      followTag: 'latest',
      image: 'plexinc/pms-docker:1.40.5.8921-836b34c27',
    },
    promtail: {
      followTag: 'latest',
      image: 'grafana/promtail:2.9.4',
    },
    prowlarr: {
      followTag: 'release',
      image: 'hotio/prowlarr:release-1.17.2.4511',
    },
    qbittorrent: {
      followTag: 'release',
      image: 'hotio/qbittorrent:release-4.6.5',
    },
    radarr: {
      followTag: 'release',
      image: 'hotio/radarr:release-5.6.0.8846',
    },
    sonarr: {
      followTag: 'release',
      image: 'hotio/sonarr:release-4.0.4.1491',
    },
    tautulli: {
      followTag: 'latest',
      image: 'tautulli/tautulli:v2.14.2',
    },
    ubuntu: {
      followTag: 'noble',
      image: 'ubuntu:noble-20240605',
    },
  },
}
