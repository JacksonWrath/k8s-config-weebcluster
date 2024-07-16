// This is adapated from Grafana's example of generating the scrape configs:
// https://github.com/grafana/loki/blob/main/production/ksonnet/promtail/scrape_config.libsonnet
//
// I wanted to be able to expand it, and it wasn't designed for that.

{
  gen_scrape_config(job_name, pod_uid):: {
    job_name: job_name,
    pipeline_stages: [{
      cri: {},
    }],
    kubernetes_sd_configs: [{
      role: 'pod',
    }],

    relabel_configs: self.prelabel_config + [
      // Only scrape local pods; Promtail will drop targets with a __host__ label
      // that does not match the current host name.
      {
        source_labels: ['__meta_kubernetes_pod_node_name'],
        target_label: '__host__',
      },

      // Drop pods without a __service__ label.
      {
        source_labels: ['__service__'],
        action: 'drop',
        regex: '',
      },

      // Include all the other labels on the pod.
      // Perform this mapping before applying additional label replacement rules
      // to prevent a supplied label from overwriting any of the following labels.
      {
        action: 'labelmap',
        regex: '__meta_kubernetes_pod_label_(.+)',
      },

      // Rename jobs to be <namespace>/<service>.
      {
        source_labels: ['__meta_kubernetes_namespace', '__service__'],
        action: 'replace',
        separator: '/',
        target_label: 'job',
        replacement: '$1',
      },

      // But also include the namespace, pod, container as separate
      // labels. They uniquely identify a container. They are also
      // identical to the target labels configured in Prometheus
      // (but note that Loki does not use an instance label).
      {
        source_labels: ['__meta_kubernetes_namespace'],
        action: 'replace',
        target_label: 'namespace',
      },
      {
        source_labels: ['__meta_kubernetes_pod_name'],
        action: 'replace',
        target_label: 'pod',  // Not 'pod_name', which disappeared in K8s 1.16.
      },
      {
        source_labels: ['__meta_kubernetes_pod_container_name'],
        action: 'replace',
        target_label: 'container',  // Not 'container_name', which disappeared in K8s 1.16.
      },

      // Populate "app" label in order of precedence in "source_labels". Skips if "app" is present
      {
        source_labels: ['app', 'app_kubernetes_io_name', 'k8s_app', 'namespace'],
        regex: ';+([^;]+).*', // Capture first string preceded by a semi-colon, up to the next semi-colon.
        action: 'replace',
        target_label: 'app',
        replacement: '$1',
      },

      // Drop extra labels that aren't useful
      {
        // These are a good idea but it's not consistently implemented so I don't rely on them (other than name above)
        action: 'labeldrop',
        regex: 'app_kubernetes_io.*|batch_kubernetes_io.*',
      },
      {
        // Extra labels on various Ceph components. 
        // I keep the two common ones: ceph_daemon_type and ceph_daemon_id
        action: 'labeldrop',
        local ceph_global_labels = 'rook_cluster|rook_io.*',
        local ceph_mon_mgr_labels = 'mon|mon_cluster|mgr|mgr_role|instance',
        local ceph_osd_labels = 'osd|ceph_osd_id|device_class|failure_domain|osd_store|portable|topology_location_.*',
        regex: std.join('|', [ceph_global_labels, ceph_mon_mgr_labels, ceph_osd_labels]),
      },
      {
        // Don't need to separate by config hashes
        action: 'labeldrop',
        regex: '.*_hash',
      },
      {
        // MinIO[-operator] labels
        action: 'labeldrop',
        regex: 'v1_min_io_console|operator',
      },
      {
        // Mimir labels
        action: 'labeldrop',
        regex: 'gossip_ring_member',
      },
      {
        // Other random labels I don't care about
        action: 'labeldrop',
        local list1 = 'statefulset_kubernetes_io.*|helm_sh.*|.*helm_cattle_io.*|version|apps_kubernetes_io_pod_index',
        local list2 = 'pod_template_generation|prometheus|upgrade_cattle_io_controller',
        regex: std.join('|', [list1, list2]),
      },

      // Kubernetes puts logs under subdirectories keyed pod UID and container_name.
      {
        source_labels: [pod_uid, '__meta_kubernetes_pod_container_name'],
        target_label: '__path__',
        separator: '/',
        replacement: '/var/log/pods/*$1/*.log',
      },
    ],
  },

  local gen_scrape_config = self.gen_scrape_config,
  scrape_configs: [
    // Scrape config to scrape any pods with a 'name' label.
    gen_scrape_config('kubernetes-pods-name', '__meta_kubernetes_pod_uid') {
      prelabel_config:: [
        // Use name label as __service__.
        {
          source_labels: ['__meta_kubernetes_pod_label_name'],
          target_label: '__service__',
        },
      ],
    },

    // Scrape config to scrape any pods with an 'app' label.
    gen_scrape_config('kubernetes-pods-app', '__meta_kubernetes_pod_uid') {
      prelabel_config:: [
        // Drop pods with a 'name' label.  They will have already been added by
        // the scrape_config that matches on the 'name' label
        {
          source_labels: ['__meta_kubernetes_pod_label_name'],
          action: 'drop',
          regex: '.+',
        },

        // Use app label as the __service__.
        {
          source_labels: ['__meta_kubernetes_pod_label_app'],
          target_label: '__service__',
        },
      ],
    },

    // Scrape config to scrape any pods with a direct controller (eg
    // StatefulSets).
    gen_scrape_config('kubernetes-pods-direct-controllers', '__meta_kubernetes_pod_uid') {
      prelabel_config:: [
        // Drop pods with a 'name' or 'app' label.  They will have already been added by
        // the scrape_config that matches above.
        {
          source_labels: ['__meta_kubernetes_pod_label_name', '__meta_kubernetes_pod_label_app'],
          separator: '',
          action: 'drop',
          regex: '.+',
        },

        // Drop pods with an indirect controller. eg Deployments create replicaSets
        // which then create pods.
        {
          source_labels: ['__meta_kubernetes_pod_controller_name'],
          action: 'drop',
          regex: '[0-9a-z-.]+-[0-9a-f]{8,10}',
        },

        // Use controller name as __service__.
        {
          source_labels: ['__meta_kubernetes_pod_controller_name'],
          target_label: '__service__',
        },
      ],
    },

    // Scrape config to scrape any pods with an indirect controller (eg
    // Deployments).
    gen_scrape_config('kubernetes-pods-indirect-controller', '__meta_kubernetes_pod_uid') {
      prelabel_config:: [
        // Drop pods with a 'name' or 'app' label.  They will have already been added by
        // the scrape_config that matches above.
        {
          source_labels: ['__meta_kubernetes_pod_label_name', '__meta_kubernetes_pod_label_app'],
          separator: '',
          action: 'drop',
          regex: '.+',
        },

        // Drop pods not from an indirect controller. eg StatefulSets, DaemonSets
        {
          source_labels: ['__meta_kubernetes_pod_controller_name'],
          regex: '[0-9a-z-.]+-[0-9a-f]{8,10}',
          action: 'keep',
        },

        // Put the indirect controller name into a temp label.
        {
          source_labels: ['__meta_kubernetes_pod_controller_name'],
          action: 'replace',
          regex: '([0-9a-z-.]+)-[0-9a-f]{8,10}',
          target_label: '__service__',
        },
      ],
    },

    // Scrape config to scrape any control plane static pods (e.g. kube-apiserver
    // etcd, kube-controller-manager & kube-scheduler)
    gen_scrape_config('kubernetes-pods-static', '__meta_kubernetes_pod_annotation_kubernetes_io_config_mirror') {
      prelabel_config:: [
        // Ignore pods that aren't mirror pods
        {
          action: 'drop',
          source_labels: ['__meta_kubernetes_pod_annotation_kubernetes_io_config_mirror'],
          regex: '',
        },

        // Static control plane pods usually have a component label that identifies them
        {
          action: 'replace',
          source_labels: ['__meta_kubernetes_pod_label_component'],
          target_label: '__service__',
        },
      ],
    },
  ],
}