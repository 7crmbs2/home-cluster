# Setting up longhorn

## label nodes

### allow scheduling on cube03
kubectl label nodes cube03 node.longhorn.io/create-default-disk=config
kubectl annotate nodes cube03 \
  'node.longhorn.io/default-disks-config=[{"path":"/mnt/raidstorage/longhorn","allowScheduling":true}]'

### list nodes that have longhorn disks

kubectl -n longhorn get nodes.longhorn.io

docs: https://longhorn.io/docs/1.9.1/nodes-and-volumes/nodes/default-disk-and-node-config/
