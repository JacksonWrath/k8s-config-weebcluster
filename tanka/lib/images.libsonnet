{
  images: {
    pihole: {
      followTag: 'latest',
      image: 'pihole/pihole:2023.05.2',
      lastChecked: '2024-01-27',
      prepullImage: 'pihole/pihole:2023.05.2', // Update this one separately first!
    },
    plex: {
      followTag: 'latest',
      image: 'plexinc/pms-docker:1.32.8.7639-fb6452ebf',
      lastChecked: '2024-01-27',
    },
    promtail: {
      followTag: 'latest',
      image: 'grafana/promtail:2.9.0',
      lastChecked: '2024-01-27',
    },
    prowlarr: {
      followTag: 'release',
      image: 'hotio/prowlarr:release-1.10.5.4116',
      lastChecked: '2024-01-27',
    },
    qbittorrent: {
      followTag: 'release',
      image: 'hotio/qbittorrent:release-4.6.1',
      lastChecked: '2024-01-27',
    },
    radarr: {
      followTag: 'release',
      image: 'hotio/radarr:release-5.1.3.8246',
      lastChecked: '2024-01-27',
    },
    sonarr: {
      followTag: 'release',
      image: 'hotio/sonarr:release-3.0.10.1567',
      lastChecked: '2024-01-27',
    },
    tautulli: {
      followTag: 'latest',
      image: 'tautulli/tautulli:v2.13.1',
      lastChecked: '2024-01-27',
    },
  },
}