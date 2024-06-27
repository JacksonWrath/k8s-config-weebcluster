local homelab = import 'homelab.libsonnet';

{
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

    @     A       10.2.69.1
    *     CNAME   %(fqdn)s.
    ns1   A       10.2.69.10
    $INCLUDE /var/bind/zones-static/%(fqdn)s.static
  ||| % {fqdn: domain}
  for domain in homelab.allDomains
}
