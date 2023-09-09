# Node Setup (Fedora)

## Installer Reminders
#### Networking
Set the hostname. Don't bother with anything else, since the GUI won't let you delete the auto-created interfaces to put them in a bond.

#### Storage
Default config does not mirror boot partitions.

Select the 2 boot drives, then do Advanced with Blivet. Create partitions as follows:
1. `600MiB` - Software RAID1 - EFI System Partition - "efi" - `/boot/efi`
1. `1GiB` - Software RAID1 - xfs - "boot" - `/boot`
1. `remaining` - Software RAID1 - physical volume (LVM) - "pv_[hostname]"

Create a LVM volume group using that last partition, then create logical volumes in that group:
1. `128GiB` - xfs - "root" - `/`
1. `128GiB` - xfs - "rancher" - `/var/lib/rancher`
1. `64GiB` - xfs - "rook" - `/var/lib/rook`

*(rancher and rook LVs may not mount automatically until the mountpoint is created manually)*

This sets things up so `mdadm` can be used to manage the arrays, rather than trying to futz with lvm wrapping it.

## Networking Config

1. Delete auto-created 10G NICs
    ```
    nmcli con del <each 10G interface UUID>
    ```
1. Create the bond
    ```
    nmcli con add type bond con-name bond0 ifname bond0 mode 802.3ad ipv4.method disabled ipv6.method disabled
    ```
1. Add the NICs
    ```
    nmcli con add type bond-slave ifname enp4s0f0 con-name enp4s0f0 master bond0
    nmcli con add type bond-slave ifname enp4s0f1 con-name enp4s0f1 master bond0
    ```
1. Create VLAN interface on bond with static IP
    ```
    nmcli con add type vlan con-name VLAN69 dev bond0 id 69 ip4 <NODE_IP>/24 gw4 <GATEWAY_IP>
    ```
1. Set DNS
    ```
    nmcli con mod VLAN69 ipv4.dns "<DNS_SERVER_IP_1> <DNS_SERVER_IP_2>"
    ```
1. Restart NetworkManager
    ```
    systemctl restart NetworkManager
    ```

## Additional Configurations

### `sysctl.d/`

These go in `/etc/sysctl.d` of each node. 

- `10-fs.inotify` - Increases inotify resources on the node.
    - Ref: https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
- `20-wireguard.conf` - Enables sysctl required for Wireguard container

### `modules-load.d/`

These go in `/etc/modules-load.d` of each node.

- `ip6table_filter` - needed for Wireguard (or the particular container image I'm using anyway)
### Enable Sysctl for Wireguard

In addition to the configs above, the sysctl config needs to be allowlisted with k3s. This is done with an argument to the kubelet. In my cluster, I have this set in the k3s config file, but it can be set in the service unit file as well.

Ref:
- https://kubernetes.io/docs/tasks/administer-cluster/sysctl-cluster/
- https://github.com/k3s-io/k3s/issues/2233

## k3s Install

Disable `firewalld`
```
systemctl disable firewalld --now
```
Disable swap
```
sudo dnf remove zram-generator-defaults
```

Copy the k3s config file to `/etc/rancher/k3s/config.yaml`, reboot, then install k3s.

First node:
```
curl -sfL https://get.k3s.io | sh -s - server --cluster-init
```
Remaining nodes:
```
curl -sfL https://get.k3s.io | sh -s - server --server https://<IP_OF_FIRST_NODE>:6443
```

Ref: https://docs.k3s.io/datastore/ha-embedded