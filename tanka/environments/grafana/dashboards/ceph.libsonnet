{
  ceph: (import 'ceph-mixin/mixin.libsonnet') {
    _config+:: {
      dashboardTags: ['ceph'],
    },
    folder: 'Ceph', 
  },
}