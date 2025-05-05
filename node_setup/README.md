# Node Setup

## Flashing OS
Before running the Ansible scripts one must Flash the Compute Models with an OS.

In this case RK1: https://docs.turingpi.com/docs/turing-rk1-flashing-os

And because we are using a SSD, we need to copy the install onto the nvme drive in the bottom.

```bash
sudo ubuntu-rockchip-install /dev/nvme0n1
```

Now we should update the Compute Module.

```bash
sudo apt update && sudo apt upgrade -y
```

Later we will be able to update the nodes via ansible but we still want to update them once now.

Note:
When flashing a Node again, make sure to remove the NVMe Drive since it will prioritize this over the eMMC Storage

## Ansible
Now we can use Ansible to bootstrap the nodes.
A few things like storage will be done manually to ensure no changes in the future through broken scripts.

Things like MetalLB I might migrate at some point but probalby when I rework this whole thing.

## Finishing the Node Setup
We not only need the bootstraping of the nodes, we also need to configure the cluster inside the nodes.

The following steps need to be done in order.

### Install and configure MetalLB
This will be done in the cli as I don't want to make changes to this config yet. I could use my own values file and stuff or make my own chart but atm this is not necessary.

```bash
helm repo add metallb https://metallb.github.io/metallb &&\
helm upgrade --install metallb metallb/metallb --create-namespace --namespace metallb-system --wait
```

Then we need to specify the range metallb is allowed to use:

WE ALSO HAVE THIS FILE IN THE DEPLOYMENTS FOLDER

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.178.205-192.168.178.215
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
EOF
```

Note:
Since there is a lot of stuff that is critical I really dont want to be doing the nfs install via ansible, I dont want to erase all my data by accident so formatting etc. will be done manually but will be documented inside NFS_install.md.

TODO:
- storage box holen
- backup einrichten
