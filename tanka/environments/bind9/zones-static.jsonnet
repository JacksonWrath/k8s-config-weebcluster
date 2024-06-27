local homelab = import 'homelab.libsonnet';

local ipMap = {
  asuna: homelab.nfs.asuna.ipv4,
  kirito: homelab.nfs.kirito.ipv4,
};

local defaultZoneContents = |||
  aomine      A       10.1.69.101
  asuna       A       %(asuna)s
  crs317      A       172.16.20.217
  firewall    A       172.17.0.1
  kagami      A       10.1.69.102
  kirito      A       %(kirito)s
  kuroko      A       10.1.69.103
  saitama     A       10.1.69.69
  vyos-asuna  A       172.17.0.3
  vyos-kirito A       172.17.0.4
||| % ipMap;

{
  [domain + '.static']: defaultZoneContents
  for domain in homelab.allDomains
}
