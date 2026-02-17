# How to run the ansible stuff

## Directory Structure

execution:
Collection of playbooks to collect certain actions into a single playbook.

meta:
Contains meta information about this ansible playbook.

playbooks:
Contains all the playbooks being used here.

templates:
Contains all templates for files that should be copied to the hosts.
The even use variables.

inventory:
Listing of all nodes, the infrastructure inventory

It is intended to only run the execution playbooks. The other stuff is just for better readability and structure.

## Actually executing playbooks

As mentioned we intend to only execute collections of playbooks from the execution directory.

The network configuration needs to be done separatly since the connection will break down with the change of the IP Address

```bash
cd ansible

ansible-playbook ./execution/initial_network.yml -i inventory --check
```

## Creating a backup

We use borg and storage box for backups.

```bash
cd ansible

ansible-playbook ./execution/borg_backup.yml -i inventory -e @secrets.enc --ask-vault-pass --check
```

Before the backup will work we also have to init it once.
```bash
borg init ssh://uXXXXXX@uXXXXXX.your-storagebox.de:23/./backup --encryption=repokey
```

## Using Ansible Vault

### Running Playbooks

The key extension to this is decrypting the vault file while running the playbook and decrypting it only when needing to edit it.
NEVER push decrypted vault file in git.

```bash
-e @secrets.enc --ask-vault-pass
```

```bash
ansible-playbook ./execution/k3s_install.yml -i inventory -e @secrets.enc --ask-vault-pass --check
```

### Editing the Vault File

This is actually best practise for changing stuff. This way you cant forget to lock the file again.

```bash
ansible-vault edit secrets.enc 
```

### (Un)Locking the Vault File

This should only be done when making a lot of changes. In both cases you will be prompted for the ansible vault password.

```bash
ansible-vault decrypt secrets.enc 

ansible-vault encrypt secrets.enc
```

When the vault file is decrypted it should be treated as vars file :eyes:

```bash
--extra-vars "@secrets.enc"
```

```bash
ansible-playbook ./execution/k3s_install.yml -i inventory --extra-vars "@secrets.enc"
```

## Execution order

This is the order you would want to execute the playbooks.

```bash
ansible-playbook ./execution/initial_network.yml -i inventory --check

ansible-playbook ./execution/initial_setup.yml -i inventory --check

ansible-playbook ./execution/k3s_install.yml -i inventory --extra-vars "@secrets.enc" --ask-vault-pass --check

ansible-playbook ./execution/k3s_network.yml -i inventory --extra-vars "@secrets.enc" --ask-vault-pass --check

ansible-playbook ./execution/k3s_upgrade.yml -i inventory --extra-vars "@secrets.enc" --ask-vault-pass --check

ansible-playbook ./execution/update_nodes.yml -i inventory --check
```

## Finalizing
This is all that is done with ansible, now we also want to make some deployments to bootstrap our cluster.

We need metallb and argocd for starters.

Follow the install:

TODO add export KUBECONFIG=/etc/rancher/k3s/k3s.yaml this to the node config! in bashrc maybe or i think theres a module even for setting env vars but idk if thats the ansible kontext
