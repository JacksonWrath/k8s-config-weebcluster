{
  images: {
    plex: {
      image: 'plexinc/pms-docker:1.32.8.7639-fb6452ebf',
      followTag: 'latest',
    },
    qbittorrent: {
      image: 'hotio/qbittorrent:release-4.6.1',
      followTag: 'release',
    },
    sonarr: {
      image: 'hotio/sonarr:release-3.0.10.1567',
      followTag: 'release',
    },
    radarr: {
      image: 'hotio/radarr:release-5.1.3.8246',
      followTag: 'release',
    },
    prowlarr: {
      image: 'hotio/prowlarr:release-1.10.5.4116',
      followTag: 'release',
    },
    promtail: {
      image: 'grafana/promtail:2.9.0',
      followTag: 'latest',
    },
    pihole: {
      image: 'pihole/pihole:2023.05.2',
      followTag: 'latest',
      prepullImage: 'pihole/pihole:2023.05.2', // Update this one separately first!
    },
    tautulli: {
      image: 'tautulli/tautulli:v2.13.1',
      followTag: 'latest',
    },
  },
}