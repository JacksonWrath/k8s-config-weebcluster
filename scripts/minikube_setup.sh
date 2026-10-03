#!/usr/bin/env bash
set -euo pipefail

DOCKER_MAC_NET_CONNECT_SERVICE="system/homebrew.mxcl.docker-mac-net-connect"
MINIKUBE_SUBNET="192.168.49.0/24"

#######################################
echo ""
echo "=== Docker Network Check ==="
#######################################

daemon_state="$(
	launchctl print "${DOCKER_MAC_NET_CONNECT_SERVICE}" 2>/dev/null |
		awk -F ' = ' '/^[[:space:]]*state = / { print $2; exit }' ||
		true
)"

if [ "${daemon_state}" != "running" ]; then
	echo "ERROR: The docker-mac-net-connect system service is not running." >&2
	echo "Restart it with:" >&2
	echo "  sudo brew services restart docker-mac-net-connect" >&2
	exit 1
fi

echo "docker-mac-net-connect is running"

route_interface="$(
	netstat -rn -f inet |
		awk '$1 == "192.168.49" || $1 == "192.168.49/24" { print $NF; exit }'
)"

if [[ ! "${route_interface}" =~ ^utun[0-9]+$ ]]; then
	echo "ERROR: ${MINIKUBE_SUBNET} is not routed through docker-mac-net-connect." >&2
	echo "Restart it with:" >&2
	echo "  sudo brew services restart docker-mac-net-connect" >&2
	exit 1
fi

echo "${MINIKUBE_SUBNET} is routed through ${route_interface}"


#######################################
echo ""
echo "=== Host Configuration ==="
#######################################

echo "Adding api.miniweeb.local to /etc/hosts for bootstrapping."
# Clean up any existing hosts entries first to avoid duplicates
sudo sed -i '' '/miniweeb.local/d' /etc/hosts || true
# Add bootstrapping entry for the API server
echo "192.168.49.100 api.miniweeb.local" | sudo tee -a /etc/hosts >/dev/null

# Configure macOS DNS resolver to point to Bind9 in-cluster DNS service (192.168.49.12)
if [ ! -f /etc/resolver/miniweeb.local ]; then
	echo "Creating /etc/resolver/miniweeb.local (requires sudo)..."
	sudo mkdir -p /etc/resolver
	echo "nameserver 192.168.49.12" | sudo tee /etc/resolver/miniweeb.local >/dev/null
	sudo killall -HUP mDNSResponder
fi

# Point the kubeconfig cluster to the resolver address so Tanka can find it
echo "Setting kubeconfig cluster miniweeb server to api.miniweeb.local..."
kubectl config set-cluster miniweeb --server=https://api.miniweeb.local:6443


#######################################
echo ""
echo "=== Minikube Configuration ==="
#######################################

# Remove the load balancer exclusion label so MetalLB can advertise IPs on a single-node cluster
echo "Removing load balancer exclusion label from node miniweeb..."
kubectl label node miniweeb node.kubernetes.io/exclude-from-external-load-balancers- --overwrite || true

# Enable volume snapshots and hostpath driver CSI addons
echo "Enabling volume snapshots and hostpath driver addons..."
minikube addons enable volumesnapshots -p miniweeb
minikube addons enable csi-hostpath-driver -p miniweeb

# Install k3s helm-controller CRD and operator
if [ -z "${HELM_CONTROLLER_VERSION:-}" ]; then
  HELM_CONTROLLER_URL="https://github.com/k3s-io/helm-controller/releases/latest/download/deploy-cluster-scoped.yaml"
  echo "Installing k3s helm-controller (latest)..."
else
  HELM_CONTROLLER_URL="https://github.com/k3s-io/helm-controller/releases/download/${HELM_CONTROLLER_VERSION}/deploy-cluster-scoped.yaml"
  echo "Installing k3s helm-controller (version: ${HELM_CONTROLLER_VERSION})..."
fi

kubectl apply -f "${HELM_CONTROLLER_URL}"

# Update CoreDNS upstream DNS resolver to point to host DNS server 10.2.69.11
# (Fixes Docker Desktop for Mac issue where CoreDNS forwarding to 192.168.65.254 times out on pod subnets)
echo "Setting CoreDNS upstream resolver to 10.2.69.11..."
kubectl get configmap coredns -n kube-system -o yaml | sed 's|forward . /etc/resolv.conf|forward . 10.2.69.11|g' | kubectl apply -f -
kubectl rollout restart deployment/coredns -n kube-system
