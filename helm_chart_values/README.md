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
kubectl create namespace kasten-io

kubectl create -f k10-dashboard-htpasswd.yaml

helm install k10 kasten/k10 -n kasten-io -f kasten-k10-values.yaml
```

### Cert Manager
```
helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace -f cert-manager-values.yaml
```
Then apply manifests in `cert-manager/`

### Gitea
```
kubectl create namespace gitea

kubectl create -f gitea-admin-auth.yaml -f gitea-db-auth.yaml

helm install gitea gitea-charts/gitea -n gitea -f gitea-values.yaml
```