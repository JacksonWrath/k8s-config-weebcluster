{
  images: {
    graphite_exporter: {
      followTag: 'latest',
      image: 'prom/graphite-exporter:v0.16.0',
    },
    kube_state_metrics: {
      followTag: '2.12.0',
      image: 'bitnami/kube-state-metrics:2.12.0-debian-12-r10',
    },
    matrix_synapse: {
      followTag: 'latest',
      image: 'matrixdotorg/synapse:v1.115.0',
    },
    node_exporter: {
      followTag: 'latest',
      image: 'prom/node-exporter:v1.8.2',
    },
    pihole: {
      followTag: 'latest',
      image: 'pihole/pihole:2024.07.0',
      prepullImage: 'pihole/pihole:2024.07.0',
    },
    plex: {
      followTag: 'latest',
      image: 'plexinc/pms-docker:1.41.1.9057-af5eaea7a',
    },
    promtail: {
      followTag: 'latest',
      image: 'grafana/promtail:2.9.4',
    },
    prowlarr: {
      followTag: 'release',
      image: 'hotio/prowlarr:release-1.25.4.4818',
    },
    qbittorrent: {
      followTag: 'release',
      image: 'hotio/qbittorrent:release-5.0.1',
    },
    radarr: {
      followTag: 'release',
      image: 'hotio/radarr:release-5.14.0.9383',
    },
    sonarr: {
      followTag: 'release',
      image: 'hotio/sonarr:release-4.0.10.2544',
    },
    tautulli: {
      followTag: 'latest',
      image: 'tautulli/tautulli:v2.14.6',
    },
    ubuntu: {
      followTag: 'noble',
      image: 'ubuntu:noble-20240605',
    },
    unifiNetworkApplication: {
      followTag: 'latest',
      image: 'linuxserver/unifi-network-application:version-8.5.6',
    },
  },
}
