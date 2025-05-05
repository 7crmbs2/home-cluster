# home-cluster
This repository is an attempt of a nice, maintainable little home cluster.
I am running the Turing Pi 2 Board with two RK1 and two 16TB HDDs at the moment.

## Setup

We will be configuring the nodes inside node_setup and use ansible to configure each cluster node.

The ansible setup includes tweaking some files to get the core node setup like networking, storage and the kubernetes install aswell as housekeeping.

There is also a manual part for configuring the raid and disk encryption.

Backups should be included into the Ansible setup at some point.
