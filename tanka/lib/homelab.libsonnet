// A library for stuff (mostly constants) about my homelab in general

{
  nfs: {
    kirito: {
      local kirito = self,
      server: 'kirito.bukkake.cafe',
      poolPath: '/mnt/kirito-pool',
      shares: {
        YoRHa: kirito.poolPath + '/YoRHa',
        LongTerm: kirito.poolPath + '/LongTerm',
      },
      totalSize: '58Ti',
    },
  },
}