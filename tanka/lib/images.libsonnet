{
  images: {
    cnpgPostgres: {
      followTag: '17',
      image: 'ghcr.io/cloudnative-pg/postgresql:17.2',
    },
    gluetun: {
      followTag: 'v3',
      image: 'qmcgaw/gluetun:v3.39.1',
    },
    grafana: {
      followTag: 'latest',
      image: 'grafana/grafana:11.5.2',
    },
    graphite_exporter: {
      followTag: 'latest',
      image: 'prom/graphite-exporter:v0.16.0',
    },
    immich: {
      followTag: 'release',
      image: 'ghcr.io/immich-app/immich-server:v1.123.0',
    },
    immichML: {
      followTag: 'release',
      image: 'ghcr.io/immich-app/immich-machine-learning:v1.123.0',
    },
    immichPostgres: {
      followTag: '16-v0.3.0',
      image: 'ghcr.io/tensorchord/cloudnative-pgvecto.rs:16.5-v0.3.0',
    },
    kube_state_metrics: {
      followTag: 'v2.12.0',
      image: 'registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.12.0',
    },
    matrix_synapse: {
      followTag: 'latest',
      image: 'matrixdotorg/synapse:v1.115.0',
    },
    node_exporter: {
      followTag: 'latest',
      image: 'prom/node-exporter:v1.9.0',
    },
    pihole: {
      followTag: 'latest',
      image: 'pihole/pihole:2024.07.0',
      prepullImage: 'pihole/pihole:2025.02.4',
    },
    plex: {
      followTag: 'latest',
      image: 'plexinc/pms-docker:1.41.4.9463-630c9f557',
    },
    port_updater: {
      followTag: 'latest',
      image: 'ghcr.io/jacksonwrath/gluetun-qbt-port-updater:v1.0.1',
    },
    promtail: {
      followTag: 'latest',
      image: 'grafana/promtail:3.4.2',
    },
    prowlarr: {
      followTag: 'release',
      image: 'hotio/prowlarr:release-1.31.2.4975',
    },
    qbittorrent: {
      followTag: 'release',
      image: 'hotio/qbittorrent:release-5.0.4',
    },
    radarr: {
      followTag: 'release',
      image: 'hotio/radarr:release-5.18.4.9674',
    },
    redis: {
      followTag: '6-alpine',
      image: 'redis:6.2.16-alpine',
    },
    sonarr: {
      followTag: 'release',
      image: 'hotio/sonarr:release-4.0.13.2932',
    },
    tautulli: {
      followTag: 'latest',
      image: 'tautulli/tautulli:v2.15.1',
    },
    ubuntu: {
      followTag: 'noble',
      image: 'ubuntu:noble-20241118.1',
    },
    unifiNetworkApplication: {
      followTag: 'latest',
      image: 'linuxserver/unifi-network-application:version-8.6.9',
    },
  },
}
