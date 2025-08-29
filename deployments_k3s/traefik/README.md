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

Then upgrade the helm install:
```bash
helm upgrade traefik traefik/traefik -n traefik -f values.yaml
```

If the repo is not found it needs to be added:
```bash
helm repo add traefik https://traefik.github.io/charts
```
