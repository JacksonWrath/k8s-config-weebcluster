local homelab = import 'homelab.libsonnet';

local ipMap = {
  asuna: homelab.nfs.asuna.ipv4,
  kirito: homelab.nfs.kirito.ipv4,
  aomine: homelab.k8s.weebcluster.ipv4.aomine,
  kagami: homelab.k8s.weebcluster.ipv4.kagami,
  kuroko: homelab.k8s.weebcluster.ipv4.kuroko,
  miniweeb: homelab.k8s.miniweeb.ipv4.api,
  weebcluster: homelab.k8s.weebcluster.ipv4.api,
};

local defaultZoneContents = |||
  aomine      A       %(aomine)s
  asuna       A       %(asuna)s
  crs305      A       10.1.69.205
  crs317      A       10.1.69.217
  firewall    A       172.17.0.1
  kagami      A       %(kagami)s
  kirito      A       %(kirito)s
  kuroko      A       %(kuroko)s
  saitama     A       10.1.69.69
  vyos-asuna  A       172.17.0.3
  vyos-kirito A       172.17.0.4
  weebcluster A       %(weebcluster)s
||| % ipMap;

{
  [domain + '.static']: defaultZoneContents
  for domain in homelab.allDomains
}
