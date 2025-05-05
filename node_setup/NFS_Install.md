# The NFS provider and RAID with Samba

This is the easiest and most straightforward option, which requires the least amount of physical disks. In this setup, we will convert Node3 to double as a Samba server. Node3 is connected to two SATA ports on the Turing Pi V2. 
There are two 16tb drives attached to the SATA ports.

Warning: It is important to note that you should not hot-plug the disk. To do this, shut down the node using the $tpi command or through the BMC web interface, plug in the disk, and then restart the node.

Show disks:

```bash
fdisk -l
```

## Configure RAID for the drives
For this mdadm and luks (or cryptsetup) are necessary. Both of these are preinstalled on the node.
Done with this tutorial: https://medium.com/@qkwpkztvx/simple-way-to-create-raid-1-array-with-luks-encryption-01872a6e580a

If there is already something setup, do this to undo old changes.

Reset raid on the drives.

```bash
sudo mdadm --zero-superblock /dev/firstdevice
sudo mdadm --zero-superblock /dev/seconddevice
```

Remove existing references to /dev/md0 in the following files.

```bash /etc/fstab
# inside /etc/fstab
/dev/md0 /mnt/md0 ext4 defaults,nofail,discard 0 0
```

```bash
# inside /etc/mdadm/mdadm.conf
ARRAY /dev/md0 metadata=1.2 ...
```

Update the initramfs to remove these references

```bash
sudo update-initramfs -u
```

## creation of the RAID 1 array

Enter the following command and press y. Make sure you use the correct devices!
```bash
sudo mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sda /dev/sdb
```

Setup encryption using LUKS
```bash
sudo cryptsetup --verbose --verify-passphrase luksFormat /dev/md0
```

Open the encrypted RAID array
```bash
sudo cryptsetup luksOpen /dev/md0 raidstorage
```

Create filesystem with Ext4
```bash
sudo mkfs.ext4 /dev/mapper/raidstorage
```

Make the directory raidstorage in the folder
```bash
sudo mkdir -p /mnt/raidstorage
```

Mount the RAID
```bash
sudo mount /dev/mapper/raidstorage /mnt/raidstorage
```

Check the RAID and make sure the size is visible
```bash
df -h -x devtmpfs -x tmpfs
```

Save the array layout
```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
```

Update the initramfs to add these references
```bash
sudo update-initramfs -u
```

Add the new filesystem mount options to the /etc/fstab for auto mounting at boot
```bash
echo '/dev/md0 /mnt/raidstorage ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab
```

Get ownership of the folder to add files
```bash
sudo chown ubuntu:ubuntu /mnt/raidstorage
```

And there it is! Do try out your new encrypted NAS by multiple copies and restarts before you add important files :-)

## Install NFS server
```bash
apt install -y nfs-server  
```

Tell NFS what to export  
```bash
echo "/mnt/raidstorage *(rw,no_subtree_check,no_root\_squash)" | tee -a /etc/exports  
```

Enable and start NFS server  
```bash
systemctl enable --now nfs-server  
```  

Tell NFS server to reload and re-export what's in /etc/exports (just in case)  
```bash
exportfs -ar  
```

## Check if the /mnt/raidstorage is exported  
```bash
showmount -e localhost  
```

Expected output:
```bash
Export list for localhost:  
/mnt/raidstorage \*
```

## Install NFS client

On every single node, install NFS client. We do this with ansible but I did do this once manually:

```bash
sudo apt install -y nfs-common
```

## Install NFS StorageClass

In Kubernetes, a StorageClass is a way to define a set of parameters for a specific type of storage that is used in a cluster. This type of storage is used by Persistent Volumes (PVs) and Persistent Volume Claims (PVCs).

A Persistent Volume (PV) is a piece of storage in the cluster that has been dynamically provisioned, and it represents a specific amount of storage capacity.

A Persistent Volume Claim (PVC) is a request for storage by a user. It asks for a specific amount of storage to be dynamically provisioned based on the specified StorageClass. The PVC is then matched to a PV that meets the requirements defined in the PVC, such as storage capacity, access mode, and other attributes.

The relationship between PVs, PVCs and StorageClasses is that the PVC specifies the desired storage attributes and the StorageClass provides a way to dynamically provision the matching PV, while the PV represents the actual piece of storage that is used by the PVC.

We are going to use nfs-subdir-external-provisioner and install it via Helm. Please do the following on your master node.

---

Add repo to helm
```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
```

Install
```bash  
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=192.168.178.203 --set nfs.path=/mnt/raidstorage --create-namespace --namespace nfs-system
```

Note, we have specified IP of our NFS server (Node3), and what is the exported path.

Check if you have StorageClass with "kubectl get storageclas":

```bash
root@cube01:~# kubectl get storageclass  
NAME PROVISIONER RECLAIMPOLICY VOLUMEBINDINGMODE ALLOWVOLUMEEXPANSION AGE  
nfs-client cluster.local/nfs-subdir-external-provisioner Delete Immediate true 10m
```

## Test

We are going to create a Persistent Volume Claim (PVC) using the recently created StorageClass and test it with a test application.

The process will involve using test files from a git repository, which you can preview in your browser. The first file will define the PVC with a size of 1 MB and the second file will create a container, mount the PVC, and create a file named "SUCCESS". This will help us verify if the entire process happens without any problems.

On your master node:

```bash
kubectl create -f https://raw.githubusercontent.com/kubernetes-sigs/nfs-subdir-external-provisioner/master/deploy/test-claim.yaml
```

Check:

```bash
root@cube01:~# kubectl get pv  
NAME CAPACITY ACCESS MODES RECLAIM POLICY STATUS CLAIM STORAGECLASS REASON AGE  
pvc-f512863d-6d94-4887-a7ff-ab05bf384f39 1Mi RWX Delete Bound default/test-claim nfs-client 11s  
  
root@cube01:~# kubectl get pvc  
NAME STATUS VOLUME CAPACITY ACCESS MODES STORAGECLASS AGE  
test-claim Bound pvc-f512863d-6d94-4887-a7ff-ab05bf384f39 1Mi RWX nfs-client 15s
```

We have requested PVC of 1MB and StorageClass using the NFS server created PV of size 1MB

Create POD:
```bash
kubectl create -f https://raw.githubusercontent.com/kubernetes-sigs/nfs-subdir-external-provisioner/master/deploy/test-pod.yaml
```

Check:
```bash
root@cube01:~# kubectl get pods  
NAME READY STATUS RESTARTS AGE  
test-pod 0/1 Completed 0 45s
```

Test pod started, and finished ok. Now we should have something in /mnt/raidstorage on our NFS server (Node3)
```bash
root@cube03:~# cd /mnt/raidstorage  
root@cube03:/mnt/raidstorage# ls  
default-test-claim-pvc-f512863d-6d94-4887-a7ff-ab05bf384f39 lost+found  
root@cube03:/mnt/raidstorage# cd default-test-claim-pvc-f512863d-6d94-4887-a7ff-ab05bf384f39/  
root@cube03:/mnt/raidstorage/default-test-claim-pvc-f512863d-6d94-4887-a7ff-ab05bf384f39# ls  
SUCCESS
```

As you can see there is a folder "default-test-claim-pvc-...." and in it file called SUCCESS.
Cleanup

To remove the tests, we can call the same files in reverse order with "delete":
```bash
kubectl delete -f https://raw.githubusercontent.com/kubernetes-sigs/nfs-subdir-external-provisioner/master/deploy/test-pod.yaml  
kubectl delete -f https://raw.githubusercontent.com/kubernetes-sigs/nfs-subdir-external-provisioner/master/deploy/test-claim.yaml
```

We can now assume the test was successful and this StorageClass can be used across our cluster.

TODO do this with ansible also

# Configure SAMBA Share
Install samba on cube03.
```bash
sudo apt install samba
```

Edit the smb config:
```bash
sudo vim /etc/samba/smb.conf
```

```/etc/samba/smb.conf
[sambashare]
    comment = Samba on Ubuntu
    path = /mnt/raidstorage/samba
    read only = no
    browsable = yes
```

And then restart the service:
```bash
sudo service smbd restart
```

## Adding Users to samba
To add a new user to user the samba share do this:

First create a new user on the system:
```bash
sudo useradd test
```

```bash
sudo smbpasswd -a test
```

## TODO could do
- configure mail alerting?
- maybe should also do grafana alerting?
