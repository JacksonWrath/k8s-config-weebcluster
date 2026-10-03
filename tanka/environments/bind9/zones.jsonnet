local homelab = import 'homelab.libsonnet';
{
  generateZones(dnsIp, ingressIp):: {
    [domain]: |||
      $TTL 60 ; 1 minute
      @   SOA  %(fqdn)s. root.%(fqdn)s. (
            16  ; serial
            60  ; refresh (1 minute)
            60  ; retry (1 minute)
            60  ; expire (1 minute)
            60  ; minimum (1 minute)
          )
          NS      ns1.%(fqdn)s.

      @     A       %(ingress)s
      *     CNAME   %(fqdn)s.
      ns1   A       %(ns1)s
      $INCLUDE /var/bind/zones-static/%(fqdn)s.static
    ||| % {
      fqdn: domain,
      ns1: dnsIp,
      ingress: ingressIp,
    }
    for domain in homelab.allDomains
  }
}
