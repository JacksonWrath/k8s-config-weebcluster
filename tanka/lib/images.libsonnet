{
  images: {
    pihole: {
      followTag: 'latest',
      image: 'pihole/pihole:2024.01.0',
      prepullImage: 'pihole/pihole:2024.01.0',
    },
    plex: {
      followTag: 'latest',
      image: 'plexinc/pms-docker:1.32.8.7639-fb6452ebf',
    },
    promtail: {
      followTag: 'latest',
      image: 'grafana/promtail:2.9.4',
    },
    prowlarr: {
      followTag: 'release',
      image: 'hotio/prowlarr:release-1.12.2.4211',
    },
    qbittorrent: {
      followTag: 'release',
      image: 'hotio/qbittorrent:release-4.6.3',
    },
    radarr: {
      followTag: 'release',
      image: 'hotio/radarr:release-5.2.6.8376',
    },
    sonarr: {
      followTag: 'release',
      image: 'hotio/sonarr:release-4.0.1.929',
    },
    tautulli: {
      followTag: 'latest',
      image: 'tautulli/tautulli:v2.13.4',
    },
  },
}
