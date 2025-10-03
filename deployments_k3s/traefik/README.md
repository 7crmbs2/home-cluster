# Update changes on traefik
state: 03.10.2025

traefik is done with k3s traefik!
If this ever needs to be reapplied or something we can actually just apply the config on the server:

```bash
ssh ubuntu@cube01
sudo kubectl apply -f /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
```

# enable the traefik dashboard
```bash
kubectl apply -f traefikdashboard.yaml
```

# disable the traefik dashboard
```bash
kubectl delete -f traefikdashboard.yaml
```

# Access Dashboard
Add the IP with the traefik hostname to your hosts file.

Then you can access it via http://traefik.local/dashboard/#/

# Add self signed TLS Encryption

Create a self signed certificate:
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout cluster.key \
  -out cluster.crt \
  -subj "/CN=*.cluster" \
  -addext "subjectAltName=DNS:*.cluster,DNS:cluster"
```
Upload it as secret:
```bash
kubectl create secret tls traefik-default-cert \
  --cert=cluster.crt \
  --key=cluster.key \
  -n kube-system
```

Then we need to use this secret and put it into a TLS Store:
```bash
k apply -f tlsstore.yaml
```

After this we need to allow this self signed certificate on our nixos machine:
```bash
kubectl get secret traefik-default-cert -n kube-system -o jsonpath='{.data.tls\.crt}' | base64 --decode > traefik-wildcard.crt
```





Take the helm-config.yaml and move it to /var/lib/rancher/k3s/server/manifests/traefik-config.yaml on the cube01.


TODO Maybe add the dashboard settings into there aswell











OLD AND WRONG:

Then upgrade the helm install:
```bash
helm upgrade traefik traefik/traefik -n traefik -f values.yaml
```

If the repo is not found it needs to be added:
```bash
helm repo add traefik https://traefik.github.io/charts
```
