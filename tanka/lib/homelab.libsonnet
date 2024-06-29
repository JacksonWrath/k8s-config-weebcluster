// A library for stuff (mostly constants) about my homelab in general

{
  local homelab = self,
  nfs: {
    local nfs = self,
    local shares = ['YoRHa', 'LongTerm'],
    generate_shares(poolPath):: {
      [share]: poolPath + '/' + share
      for share in shares
    },

    currentPrimary: self.asuna,
    
    asuna: {
      server: 'asuna.' + homelab.defaultDomain,
      ipv4: '10.1.69.120',
      poolPath: '/mnt/asuna-pool/sao',
      shares: nfs.generate_shares(self.poolPath),
      totalSize: '58Ti',
    },
    kirito: {
      server: 'kirito.' + homelab.defaultDomain,
      ipv4: '10.1.69.121',
      poolPath: '/mnt/kirito-pool/sao',
      shares: nfs.generate_shares(self.poolPath),
      totalSize: '58Ti',
    },
  },
  defaultDomain: 'waifus.dev',
  additionalDomains: [
    // Additional domains here will be added to most ingresses
  ],
  allDomains: [self.defaultDomain] + self.additionalDomains,
}