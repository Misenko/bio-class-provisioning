# BIO class provisioning
This repository contains a set of scripts used to prepare a BIO class environment (almost) from scratch.

**Scripts and procedures in this repository are bind to (old) MetaCloud infrastructure and most likely won't work anywhere else.**

## Overview
There are four types of nodes in this setup:
* Salt master
* NFS server
* BIO class teacher's machine
* BIO class student's machine

### Salt master
Salt (or Saltstack) master is managing all the other nodes called salt minions (even NFS node). Salt master contains:
* recipes for all the slave nodes
* customized module for retrieving [pillar](https://docs.saltstack.com/en/latest/topics/tutorials/pillar.html) data from OpenNebula
* credentials to access OpenNebula
* 2 cron-like jobs:
  * every 5 minutes all minions are checked and recipes are applied
  * every 2 hours dead (unresponsive) minions are removed from management (turned off VMs)

Salt is installed from packages and official Salt repository. There is a service called **salt-master** (and **salt-minion** on minions) that can be controlled via systemctl.

### NFS server
This node contains a 1TB drive shared via NFS with BIO class nodes. Drive is mounted under `/nfs`. There are 2 directories present:
* `persistent` - contains home directories for each BIO class user
* `shared` - contains shared data for BIO class

Exports on these repositories are managed by Salt master and works as follows:
* `persistent/<username>` directory is exported as read-write and mounted as `/nfs/persistent` for every BIO class user
* `shared` directory is exported as read-only and mounted as `/nfs/shared` for each BIO class student
* `shared` directory is exported ad read-write and mounted as `/nfs/shared` for each BIO class teacher

### BIO class machines
Each student and teacher has its own virtual machine. Virtual machines must be run under a specific group in OpenNebula to be recognized by Salt master:
* `bioconductor` for students
* `bioconductor-teachers` for teachers

Machines also has to be run from the templates prapared by these scripts as they contain additional information on which BIO class is the virtual machine for.

#### BIO software
There is A LOT of bioinformatics software that should be available for these BIO classes. In order to speed up the delivery process Docker images containing all the required software were crated and are run within the virtual machines so that users can have ready to use environment much quicker. There are currently two BIO classes (and their required software) supported:
* Analysis of gene expression - [https://github.com/Misenko/bio-class-age](https://github.com/Misenko/bio-class-age)
* Genomics: algorithms and analysis - [https://github.com/Misenko/bio-class-gaa](https://github.com/Misenko/bio-class-gaa)

#### How it works
Salt runs a Docker container on every BIO class machine (which one depends on metadata from VM template). There is an SSH daemon running inside the container so the users login directly to the container environment instead of the virtual machine. SSH daemon is running on port `2222` and login user is called `student` (for both students and teachers). GAA class is an exception as their network won't allow SSH connections to other ports then 22.

Container mounts `/nfs/persistent` as a home directory and `/nfs/shared` is available under `/data/shared`.

There is also an RStudio server running and accessable on port `8787`. User can access it with username `student` and password automatically generated for each of them and located at file `/home/student/rstudio-pass` on their virtual machines.

#### Updates
In order to update some software (or add some) in the containers, one has to update the recipes in the above repositories and tag the new version. That will trigger a CI mechanism (using Circle CI) for building new Docker images and their registration at DockerHub. Once there, Salt master will notice the new version and update all running conatiners.

## Requirements
* OpenNebula (see [OpenNebula configuration](#opennebula-configuration) section)
* [Salt SSH](https://docs.saltstack.com/en/latest/topics/ssh/)

### OpenNebula configuration
As mentioned earlier, BIO class users are in OpenNebula divided into two groups `bioconductor` and `bioconductor-teachers`. There is one more group called `bioconductor-nfs` used for running NFS server. User used on Salt master to access OpenNebula must have read access for all these groups so Salt master can see all the BIO class virtual machines.

There are also different networks with public IP available for students and teachers. BIO class virtual machines have two network interfaces, one with public IP for access from the world and one with private IP used by Salt master to communicate with minions.

Before running any scripts, there has to be two virtual machines already running in OpenNebula with root access available - Salt master and NFS master. They don't have to be configured just running so scripts can configure them.

## Respository structure
```
.
├── bio-class-provisioning.sh
├── docker
├── opennebula
├── README.md
└── salt-ssh
    ├── cache
    ├── config
    ├── log
    ├── pki
    ├── roster
    ├── salt
    │   ├── BIO class provisioning recipes
    │   ├── salt-master
    │   │   └── salt
    │   │       ├── BIO class recipes
    │   │       │   .
    │   │       │   .
    │   │       │   .
    |   |   .
    |   |   .
    |   |   .
    └── Saltfile
```

* `docker` - Docker compose descriptors for running Cloudkeeper and Imagemaster
* `opennebula` - OpenNebula template and image templates to be used for image registration via Cloudkeeper
* `salt-ssh` - Salt SSH recipes for Salt master (**not BIO class recipes!**)
* `salt-ssh/salt/salt-master` - Salt recipes for BIO classes

## First (and only) run
The whole provisioning mechanism is started by runnins `bio-class-provisioning.sh` Bash script. Before running the script one must fill in missing environment variables at the top of the file.

**Once run, script shouldn't be run again!. BIO class orchestration is then managed from Salt master only!**

### What's happening during the run
* Copy Salt SSH recipes into a temporary directory where every occurence of environment variable is substituted
* Run Imagemaster to prepare images
* Run Cloudkeeped to register images and create templates
* Run Salt SSH to provision Salt master
* Cleanup

Once all this is done there should be a working BIO class setup running in OpenNebula.

## Common Saltstack commands
* `salt '*' test.ping` - ping all minons, good for testing network connectivity
* `salt '*' pillar.items` - (re)load pillar data, in our case from OpenNebula
* `salt-run state.orchestrate orch.bio` - run BIO class orchestration
* `salt-run state.orchestrate orch.management` - remove unresponsive (most likely dead) minions

## Troubleshooting
### Accents in virtual machine name
OpenNebula pillar this setup is using doesn't support accents and the whole thing throws weird errors. Make sure no virtual machine has accents in its name.

### Minions are not responding to ping
This usually means that either network is down or it was down and network interfaces on virtual machines didn't get their IPs back. Restarting minions usually solves the problem.

### Student/teacher cannot access their VM
In 99.9% of cases they have bad or different SSH public key registered in Perun. So check that first.
