// A library for stuff (mostly constants) about my homelab in general

{
  nfs: {
    local nfs = self,
    local shares = ['YoRHa', 'LongTerm'],
    generate_shares(poolPath):: {
      [share]: poolPath + '/' + share
      for share in shares
    },
    
    asuna: {
      server: 'asuna.bukkake.cafe',
      poolPath: '/mnt/asuna-pool/sao',
      shares: nfs.generate_shares(self.poolPath),
      totalSize: '58Ti',
    },
    kirito: {
      server: 'kirito.bukkake.cafe',
      poolPath: '/mnt/kirito-pool',
      shares: nfs.generate_shares(self.poolPath),
      totalSize: '58Ti',
    },
  },
}