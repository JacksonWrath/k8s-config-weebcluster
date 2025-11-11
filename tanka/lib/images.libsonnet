{
  images: {
    cnpgPostgres: {
      followTag: '17',
      image: 'ghcr.io/cloudnative-pg/postgresql:17.2',
    },
    gluetun: {
      followTag: 'v3',
      image: 'qmcgaw/gluetun:v3.40.0',
    },
    grafana: {
      followTag: 'latest',
      image: 'grafana/grafana:12.2.1',
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
      image: 'registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.17.0',
    },
    matrix_synapse: {
      followTag: 'latest',
      image: 'matrixdotorg/synapse:v1.115.0',
    },
    node_exporter: {
      followTag: 'latest',
      image: 'prom/node-exporter:v1.10.2',
    },
    pihole: {
      followTag: 'latest',
      image: 'pihole/pihole:2024.07.0',
      prepullImage: 'pihole/pihole:2025.11.0',
    },
    plex: {
      followTag: 'latest',
      image: 'plexinc/pms-docker:1.42.2.10156-f737b826c',
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
      image: 'ghcr.io/hotio/prowlarr:release-2.1.5.5216',
    },
    qbittorrent: {
      followTag: 'release',
      image: 'ghcr.io/hotio/qbittorrent:release-5.1.2',
    },
    radarr: {
      followTag: 'release',
      image: 'ghcr.io/hotio/radarr:release-5.28.0.10274',
    },
    redis: {
      followTag: '6-alpine',
      image: 'redis:6.2.16-alpine',
    },
    sonarr: {
      followTag: 'release',
      image: 'ghcr.io/hotio/sonarr:release-4.0.16.2944',
    },
    tautulli: {
      followTag: 'latest',
      image: 'tautulli/tautulli:v2.16.0',
    },
    ubuntu: {
      followTag: 'noble',
      image: 'ubuntu:noble-20251001',
    },
    unifiNetworkApplication: {
      followTag: 'latest',
      image: 'linuxserver/unifi-network-application:version-v9.5.21',
    },
  },
}
