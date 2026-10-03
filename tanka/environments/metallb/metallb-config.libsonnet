{
  new(namespace, cluster)::
    local mlbConfig = cluster.metallb;

    local l2Adv = {
      apiVersion: 'metallb.io/v1beta1',
      kind: 'L2Advertisement',
      metadata: {
        name: 'l2-advertisement',
        namespace: namespace,
      },
      spec: {
        ipAddressPools: ['lb-pool'],
      },
    };

    local bgpPeer = {
      apiVersion: 'metallb.io/v1beta2',
      kind: 'BGPPeer',
      metadata: {
        name: 'vyos-peer',
        namespace: namespace,
      },
      spec: {
        myASN: mlbConfig.bgp.myASN,
        peerASN: mlbConfig.bgp.peerASN,
        peerAddress: mlbConfig.bgp.peerAddress,
      },
    };

    local bgpAdv = {
      apiVersion: 'metallb.io/v1beta1',
      kind: 'BGPAdvertisement',
      metadata: {
        name: 'bgp-advertisement',
        namespace: namespace,
      },
    };

    {
      ipPool: {
        apiVersion: 'metallb.io/v1beta1',
        kind: 'IPAddressPool',
        metadata: {
          name: 'lb-pool',
          namespace: namespace,
        },
        spec: {
          addresses: mlbConfig.addresses,
        },
      },
    } + (
      if mlbConfig.mode == 'l2' then {
        l2Adv: l2Adv,
      } else {
        bgpPeer: bgpPeer,
        bgpAdv: bgpAdv,
      }
    ),
}
