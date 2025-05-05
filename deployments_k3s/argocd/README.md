# ArgoCD inside the k3s cluster
First we have to create a new namespace for argocd.
```bash
kubectl create namespace argocd
```

I will just install this the quick way because the state will be stored inside the k3s backup and there is a ton of manual configuring I will do anyways.
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

ArgoCD will automatically generate an admin password that you can use to log in. (The default username is "admin") To get it, execute the following command:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64
```

To make my life easier I use MetalLB to assign a unique IP to the ArgoCD UI.
Change the IP to one free from range defined for MetalLB.
```bash
kubectl patch service argocd-server -n argocd --patch '{ "spec": { "type": "LoadBalancer", "loadBalancerIP": "192.168.178.206" } }'
```
