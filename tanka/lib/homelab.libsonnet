// A library for stuff (mostly constants) about my homelab in general

{
  nfs: {
    local nfs = self,
    local shares = ['YoRHa', 'LongTerm'],
    generate_shares(poolPath):: {
      [share]: poolPath + '/' + share
      for share in shares
    },

    currentPrimary: self.kirito,
    
    asuna: {
      server: 'asuna.bukkake.cafe',
      ipv4: '10.1.69.120',
      poolPath: '/mnt/asuna-pool/sao',
      shares: nfs.generate_shares(self.poolPath),
      totalSize: '58Ti',
    },
    kirito: {
      server: 'kirito.bukkake.cafe',
      ipv4: '10.1.69.121',
      poolPath: '/mnt/kirito-pool/sao',
      shares: nfs.generate_shares(self.poolPath),
      totalSize: '58Ti',
    },
  },
}