{
  'bukkake.cafe': |||
    $TTL 60 ; 1 minute
    @   SOA  bukkake.cafe. root.bukkake.cafe. (
          16  ; serial
          60  ; refresh (1 minute)
          60  ; retry (1 minute)
          60  ; expire (1 minute)
          60  ; minimum (1 minute)
        )
        NS      ns1.bukkake.cafe.

    @     A       10.2.69.1
    *     CNAME   bukkake.cafe.
    ns1   A       10.2.69.10
    $INCLUDE /var/bind/zones-static/bukkake.cafe.static
  |||,
}
