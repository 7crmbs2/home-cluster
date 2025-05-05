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
