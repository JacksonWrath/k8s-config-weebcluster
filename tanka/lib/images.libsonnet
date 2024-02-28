{
  images: {
    pihole: {
      followTag: 'latest',
      image: 'pihole/pihole:2024.02.2',
      prepullImage: 'pihole/pihole:2024.02.2',
    },
    plex: {
      followTag: 'latest',
      image: 'plexinc/pms-docker:1.40.0.7998-c29d4c0c8',
    },
    promtail: {
      followTag: 'latest',
      image: 'grafana/promtail:2.9.4',
    },
    prowlarr: {
      followTag: 'release',
      image: 'hotio/prowlarr:release-1.13.3.4273',
    },
    qbittorrent: {
      followTag: 'release',
      image: 'hotio/qbittorrent:release-4.6.3',
    },
    radarr: {
      followTag: 'release',
      image: 'hotio/radarr:release-5.3.6.8612',
    },
    sonarr: {
      followTag: 'release',
      image: 'hotio/sonarr:release-4.0.2.1183',
    },
    tautulli: {
      followTag: 'latest',
      image: 'tautulli/tautulli:v2.13.4',
    },
  },
}
