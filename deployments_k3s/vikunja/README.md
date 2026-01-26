# vikunja
Install vikunja to add to the home cluster.

To use the default helm chart we need to specify a default storage class.
```bash
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
