## Helm Chart Installs

### MetalLB
```
helm install metallb metallb/metallb -n metallb --create-namespace
```
Then apply manifests in `metallb/`

### Nginx Ingress Controller
```
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace -f ingress-nginx-values.yaml
```

### Rook Ceph Operator
```
helm install rook-ceph rook-release/rook-ceph -n rook-ceph --create-namespace
```

### Kasten K10
```
helm install k10 kasten/k10 -n kasten-io --create-namespace -f kasten-k10-values.yaml

kubectl create -f k10-dashboard-htpasswd.yaml
```

### Cert Manager
```
helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace -f cert-manager-values.yaml
```
Then apply manifests in `cert-manager/`

### Gitea
```
helm install gitea gitea-charts/gitea -n gitea --create-namespace -f gitea-values.yaml

kubectl create -f gitea-admin-auth.yaml -f gitea-db-auth.yaml
```

### Grafana
```
helm install grafana grafana/grafana -n grafana --create-namespace -f grafana-values.yaml

kubectl create -f grafana-auth.yaml
```

### Grafana Loki
MinIO setup:
1. Create the 3 buckets in `loki-values.yaml`
1. Create a policy that allows `s3:*` on those buckets and objects
1. Create a user for Loki in MinIO and assign that policy to it
1. Create an access key for that user
1. Update the keys in `loki-secret-values.yaml`
```
helm install loki grafana/loki -n loki --create-namespace -f loki-values.yaml -f loki-secret-values.yaml
```
Due to the secondary values file, when upgrading just the main values, specify `--reuse-values` so these aren't erased and you don't have to provide it every time.

### Promtail
```
helm install promtail grafana/promtail -n loki -f promtail-values.yaml
```