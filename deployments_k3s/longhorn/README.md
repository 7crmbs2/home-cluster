# Setting up longhorn

## label nodes

### allow scheduling on cube03
```bash
kubectl label nodes cube03 node.longhorn.io/create-default-disk=config
kubectl annotate nodes cube03 'node.longhorn.io/default-disks-config=[{"path":"/mnt/raidstorage/longhorn","allowScheduling":true}]'
```

### Change default storage class to longhorn
```bash
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

### list nodes that have longhorn disks

```bash
kubectl -n longhorn get nodes.longhorn.io
```

docs: https://longhorn.io/docs/1.9.1/nodes-and-volumes/nodes/default-disk-and-node-config/
