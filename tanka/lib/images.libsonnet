{
  images: {
    pihole: {
      followTag: 'latest',
      image: 'pihole/pihole:2024.05.0',
      prepullImage: 'pihole/pihole:2024.05.0',
    },
    plex: {
      followTag: 'latest',
      image: 'plexinc/pms-docker:1.40.2.8395-c67dce28e',
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
  },
}
