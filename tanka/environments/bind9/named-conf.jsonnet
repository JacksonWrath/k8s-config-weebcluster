local homelab = import 'homelab.libsonnet';

{
  'named.conf': |||
    include "/etc/bind/named.conf.options";
    include "/etc/bind/named.conf.local";
  |||,

  'named.conf.options': |||
    options {
        directory "/var/cache/bind";

        recursion yes;
        listen-on { any; };

        allow-query { any; };

        forwarders {
            1.1.1.1;
            8.8.8.8;
        };
    };
  |||,

  'named.conf.local': std.join('', [
    |||
      zone "%(fqdn)s" {
          type master;
          file "/var/bind/zones/%(fqdn)s";
      };
    ||| % { fqdn: domain }
    for domain in homelab.allDomains
  ]),
}
