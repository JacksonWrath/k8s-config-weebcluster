## Additional Host Configurations

### `10-fs.inotify.conf`

This goes in `/etc/sysctl.d` of each node. Increases inotify resources on the node.

Ref: https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files