# SysEng Quick Kubernetes Ansible Repo

- [SysEng Quick Kubernetes Ansible Repo](#syseng-quick-kubernetes-ansible-repo)
  - [Basic Information](#basic-information)
  - [YouTube Series](#youtube-series)
  - [Components](#components)
  - [Requirements](#requirements)
    - [What if I don't want to use devcontainers?](#what-if-i-dont-want-to-use-devcontainers)
      - [Using Docker Directly](#using-docker-directly)
      - [Installing Dependencies Locally](#installing-dependencies-locally)
        - [Python Packages](#python-packages)
        - [Ansible Collections](#ansible-collections)
        - [k3sup](#k3sup)
        - [kubectl](#kubectl)
        - [helm](#helm)
  - [Instructions](#instructions)
    - [Configuring the Cluster](#configuring-the-cluster)
      - [Regenerating the Inventory](#regenerating-the-inventory)
    - [Deploying VMs on Proxmox](#deploying-vms-on-proxmox)
      - [Adding Ansible Secret Values](#adding-ansible-secret-values)
      - [Configure the Proxmox Role Defaults](#configure-the-proxmox-role-defaults)
        - [proxmox\_api](#proxmox_api)
        - [proxmox\_image\_delete](#proxmox_image_delete)
        - [promox\_image\_dest](#promox_image_dest)
        - [proxmox\_node](#proxmox_node)
        - [proxmox\_template](#proxmox_template)
        - [proxmox\_timeouts](#proxmox_timeouts)
        - [proxmox\_use\_become](#proxmox_use_become)
      - [Configuring the Cloud Images](#configuring-the-cloud-images)
      - [create\_cluster playbook](#create_cluster-playbook)
      - [remove\_cluster playbook](#remove_cluster-playbook)
    - [Deploying k3s on Your VMs](#deploying-k3s-on-your-vms)
      - [Configure the k3sup Role Defaults](#configure-the-k3sup-role-defaults)
        - [k3sup\_context](#k3sup_context)
        - [k3sup\_debug](#k3sup_debug)
        - [k3sup\_extra\_args](#k3sup_extra_args)
        - [k3sup\_iface](#k3sup_iface)
        - [k3sup\_ip\_range](#k3sup_ip_range)
        - [k3sup\_k3s\_version](#k3sup_k3s_version)
        - [k3sup\_k3s\_server\_noschedule](#k3sup_k3s_server_noschedule)
        - [k3sup\_kube\_vip\_lease\_XXX](#k3sup_kube_vip_lease_xxx)
        - [k3sup\_kube\_vip\_version](#k3sup_kube_vip_version)
        - [k3sup\_local\_path](#k3sup_local_path)
        - [k3sup\_prefer\_ip](#k3sup_prefer_ip)
        - [k3sup\_ssh\_key](#k3sup_ssh_key)
        - [k3sup\_use\_kube\_vip / k3sup\_use\_kube\_vip\_cloud\_controller](#k3sup_use_kube_vip--k3sup_use_kube_vip_cloud_controller)
        - [k3sup\_vip](#k3sup_vip)
      - [deploy\_k3s playbook](#deploy_k3s-playbook)
    - [Deploying Rancher to Your Cluster](#deploying-rancher-to-your-cluster)
      - [Configure the rancher Role Defaults](#configure-the-rancher-role-defaults)
        - [rancher\_bootstrap\_password](#rancher_bootstrap_password)
        - [rancher\_cert\_manager\_version](#rancher_cert_manager_version)
        - [rancher\_debug](#rancher_debug)
        - [rancher\_hostname](#rancher_hostname)
        - [rancher\_lb\_service\_enable](#rancher_lb_service_enable)
        - [rancher\_lb\_service\_name](#rancher_lb_service_name)
        - [rancher\_replicas](#rancher_replicas)
        - [rancher\_version](#rancher_version)
      - [deploy\_rancher playbook](#deploy_rancher-playbook)
  - [Additional Resources](#additional-resources)

## Basic Information

This repo contains ansible playbooks to help you bootstrap a kubernetes cluster.
If you have proxmox, it can even build the VMs for the cluster.

## YouTube Series

I demonstrate the use of this repo in a playlist on my YouTube channel.

[Kubernetes with Ansible Playlist](https://youtube.com/playlist?list=PLvadQtO-ihXvO-SoG5YQ1LfmQcTLv2fre&si=62lOhrioFZW-VW0Z)

## Components

| Component                 | Description                                                          |
| ------------------------- | -------------------------------------------------------------------- |
| k3sup                     | Used to install k3s on the nodes                                     |
| k3s                       | The kubernetes implementation                                        |
| kube-vip                  | Manages a virtual IP (VIP) on the control plane nodes for k8s API HA |
| kube-vip cloud controller | Replacement LoadBalancer controller for k3s built-in servicelb       |
| traefik                   | Ingress controller for the cluster                                   |
| rancher                   | Cluster web GUI                                                      |

## Requirements

- At least one VM
  - k3s needs at least one node to start
  - At least 3 servers are required for HA
  - At least 2 workers are required for HA if you disable workloads on the servers
  - lxc containers might work, but probably not as these plays exist today
- Devcontainers (and Docker/Podman)
  - Not strictly required, but the requirements are bundled making it easier
- The ability to edit YAML files
  - The defaults will almost certainly need **some** tweaking

### What if I don't want to use devcontainers?

The bundled devcontainer will make it much easier to use these plays.
However, I understand this may not be for everyone.

#### Using Docker Directly

If you have docker, but don't want to use devcontainers, that's an option.

```sh
docker pull ghcr.io/sysengquick/k3s:latest
docker run --rm -it -v ".:/workspace" --name sysengquick-k3s ghcr.io/sysengquick/k3s:latest /bin/bash -c 'cd /workspace && sudo -u vscode bash'
```

You can build the image from the Dockerfile locally if you prefer.

```sh
docker build -t ghcr.io/sysengquick/k3s:latest .
docker run --rm -it -v ".:/workspace" --name sysengquick-k3s ghcr.io/sysengquick/k3s:latest /bin/bash -c 'cd /workspace && sudo -u vscode bash'
```

#### Installing Dependencies Locally

If you don't want to use the container, you'll need to install the dependencies.

Ansible only runs on Linux and macOS.
If you're using Windows, you must use WSL.

The Dockerfile is a pretty good template for what you need.
Parts of it are just for convenience.

##### Python Packages

I use poetry to manage python dependencies, but it's not required.

I've only tested this with python 3.12 and ansible-core 2.16.
Older versions might work, but have not been tested.

Once python and pip are installed, you can install the required packages.

```sh
python3 -m pip install ansible-core pyyaml
```

If you are using the proxmox plays, you will need two additional packages.

```sh
python3 -m pip install proxmoxer requests
```

##### Ansible Collections

Now that ansible is installed, you need to install the required collections.

```sh
ansible-galaxy collection install -r collections/requirements.yml
```

Ansible looks for collections in specific places.
We can add a symlink so ansible can find our sysengquick.k3s collection.

```sh
ln -s collections/sysengquick ~/.ansible/collections/ansible_collections/
```

##### k3sup

We are using k3sup to install k3s, so we'll need that.

```sh
export K3SUP_VERSION=0.13.5
sudo curl -sLSo /usr/local/bin/k3sup \
    https://github.com/alexellis/k3sup/releases/download/${K3SUP_VERSION}/k3sup
sudo chmod 755 /usr/local/bin/k3sup
```

##### kubectl

We'll need kubectl to interact with our cluster.

```sh
export KUBECTL_VERSION=v1.27.12
sudo curl -sLSo /usr/local/bin/kubectl \
    https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
sudo chmod 755 /usr/local/bin/kubectl
```

##### helm

We need helm to install cert-manager and rancher.

```sh
export HELM_VERSION=v3.14.2
pushd /tmp
curl -sLS https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin
rm -r linux-amd64
popd
```

After helm has been installed, you need to add some helm repos.

```sh
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

## Instructions

Make sure you are using the devcontainer or have the requirements installed.

### Configuring the Cluster

The playbooks need to know how the cluster should be configured.
Open the file _collections/sysengquick/k3s/playbooks/group_vars/all/cluster.yml_.

Update the cluster nodes with the names and IPs of your server and worker nodes.
You need at least one server, and three for a true HA setup.
Workers are only required if you prevent workloads from be scheduled on the servers.
This is a best practice, but is not required.

Update the node_ssh_user with the privileged user account on your nodes.
This user must have ssh key authentication configured.
It must be root or have full passwordless sudo privileges as root.

If you are using the proxmox playbooks, cloud-init will set everything up for you.

**NOTE**: The remaining keys are not important if you are not using proxmox.

In proxmox_network, set gateway and cidr as appropriate for your cluster network.

Set proxmox_server to the IP or DNS name for your proxmox API server.

Set proxmox_ssh_user to be a user on your proxmox server that can run `qm disk import` as root.
If you want to allow-list only this single command, it must be added with NOPASSWD.
Otherwise, the user must have full sudo privileges as root.

Either one of these entries should be sufficient.

```sudoers
ansible ALL=(root) NOPASSWD: /usr/sbin/qm
ansible ALL=(root) ALL
```

#### Regenerating the Inventory

After updating the cluster configuration, you must rebuild inventory.yaml.
There is a helper script to do this.

```sh
python3 scripts/update_inventory.py
```

### Deploying VMs on Proxmox

This repo contains plays for deploying VMs from cloud images to a proxmox cluster.

An API token capable of creating templates and VMs in proxmox is required.
I applied the PVEAdmin role to my token on the root resource.

#### Adding Ansible Secret Values

The proxmox playbooks require two secret values: the cloud-init user password and the proxmox API token secret.

The cloud-init user password can be anything you want.
It is only used for serial console logins in case SSH is not working.

Open vault.example.yml in _collections/sysengquick/k3s/playbooks/vars/proxmox_.
Copy the contents of this file over the contents of vault.yml.
Update the values as appropriate.

In ansible.cfg, there is a vault password file.
Write your vault password to a file and update the path as needed.
Encrypt the vault.yml file with ansible-vault.

```sh
ansible-vault encrypt --vault-pass-file /private/ansible/vault/sysengquick/k3s vault.yml
```

Replace the path in the command as appropriate.

#### Configure the Proxmox Role Defaults

Several options may need changed in the proxmox role defaults.
Open the file main.yml in _collections/sysengquick/k3s/roles/proxmox/defaults_.

##### proxmox_api

In the proxmox_api dictionary, you may need to change the token_id or user to match your token.

##### proxmox_image_delete

Change this to true if you want ansible to delete the cloud image file after it creates the template.

##### promox_image_dest

This is where the cloud image disk file is saved.

##### proxmox_node

This field must match one of the nodes in your proxmox cluster.

**NOTE**: I don't have a multi-node cluster.
If you want to place VMs on different nodes, migrate them after creation.

##### proxmox_template

This dictionary contains base settings the VMs will inherit.
You can alter the settings after creation if you want to tweak them individually.

| Template Property | Description                                                                                   |
| ----------------- | --------------------------------------------------------------------------------------------- |
| block_storage     | False for disk files (e.g. qcow2/vmdk). True for block storage devices (e.g. lvm/zfs volumes) |
| bridge            | Proxmox bridge device to attach your VM NICs                                                  |
| ciusr             | cloud-init username                                                                           |
| cipassword        | cloud-init password                                                                           |
| cores             | CPU cores                                                                                     |
| disk_format       | disk file format (e.g. qcow2/raw/vmdk) -- ignored when block_storage is true                  |
| image             | cloud image to build template from (see vars/main.yml for options)                            |
| memory            | RAM in mebibytes (i.e. powers of 2, not 10)                                                   |
| name              | Template name                                                                                 |
| size              | Disk size                                                                                     |
| ssd               | True if your storage pool is on SSD                                                           |
| sshkeys           | SSH authorized keys to add to the cloud-init user                                             |
| storage           | Promox storage pool to place the VM/template disks                                            |
| vmid              | The ID to use for the template                                                                |

##### proxmox_timeouts

The proxmox_timeouts dictionary is how long (in seconds) to wait for certain actions.

| Timeout  | Description                                            |
| -------- | ------------------------------------------------------ |
| api      | Timeout for creating a VM from the template            |
| creation | Timeout for between VM creation before continuing      |
| startup  | Timeout for SSH login to work on the newly created VMs |

##### proxmox_use_become

proxmox_use_become should be set true if your user has full sudo privileges.
If you just added the qm disk import command without a password, leave it false.

#### Configuring the Cloud Images

In the proxmox role vars, proxmox_images defines the usable cloud images.
There are four images defined currently: alma_linux_9, debian_12, ubuntu_2204, and ubuntu_2204_minimal.

I have done the most testing with debian_12 (aka bookworm), but any of these shold work.

If you want to add another cloud image, you must fill out a new entry in this dictionary.

I was not able to import Oracle Linux 8 or 9 cloud images.
Proxmox didn't seem to understand the disk format it was using.
I'd love a pull request if you can make this work.

| Image Property | Description                                                |
| -------------- | ---------------------------------------------------------- |
| base           | Base URL to download the cloud image disk and digest files |
| name           | Name of the disk image file in base                        |
| digest         | Name of the checksum file in base                          |
| method         | Hash algorithm in the digest file (e.g. sha256, sha512)    |

You should be able to concatenate the base property with the name or digest to get a full URL to the file.
The base property must end with a trailing slash.

#### create_cluster playbook

When you are done tweaking your settings, run the cluster_create playbook.

```sh
ansible-playbook sysengquick.k3s.create_cluster -K
```

If you don't need a sudo password, you can press enter when prompted or leave off the -K option.

#### remove_cluster playbook

If you want to tear down your cluster, run the remove_cluster playbook.

```sh
ansible-playbook sysengquick.k3s.remove_cluster
```

### Deploying k3s on Your VMs

Once you have your VMs, you're ready to install k3s.

**NOTE**: You do not need proxmox for this part.
Any VMs capable of running k3s should work.

#### Configure the k3sup Role Defaults

There are some values that may need updated in the k3sup role defaults.
Open `main.yml` in _collections/sysengquick/k3s/roles/k3sup/defaults_.

##### k3sup_context

This is the kubeconfig context.
It's largely cosmetic.

##### k3sup_debug

Set true to get debug output printed about the console commands run by the playbook.

##### k3sup_extra_args

Array of additional arguments to pass to k3s.

##### k3sup_iface

The default interface on the VMs.

This is needed for a few things in the playbooks.
There is no provision for handling VMs with different default interfaces.

##### k3sup_ip_range

Rnage of IPs that kube-vip cloud controller will assign to service loadbalancers.

For a single IP, make start and end the same.
This is untested, but it should work.

**NOTE**: This value is not used if kube-vip cloud controller is not used.

##### k3sup_k3s_version

The version of k3s to install.
To install rancher, make sure you pick a compatible version.

##### k3sup_k3s_server_noschedule

Set this to true to prevent scheduling workloads on control planes.

It adds the node taint node-role.kubernetes.io/control-plane:NoSchedule to the cluster.

##### k3sup_kube_vip_lease_XXX

These properties control how timeouts on the kube-vip virtual IP leadership elections.
You probably don't need to change these.

##### k3sup_kube_vip_version

Which version of kube-vip to install.

##### k3sup_local_path

Where to instll the kubectl configuration file on the local host.

##### k3sup_prefer_ip

When true, k3sup will connect to the nodes by IP and not hostname.

##### k3sup_ssh_key

Path to the SSH key k3sup will use to connect to the nodes.

##### k3sup_use_kube_vip / k3sup_use_kube_vip_cloud_controller

When true, these components will be installed on your k3s cluster.
Any combination should work (both, neither, or only one).

##### k3sup_vip

The virtual IP to share with kube-vip.

**NOTE**: This property is unused if kube-vip is not installed.

#### deploy_k3s playbook

Once your values have been set, run the deploy_k3s playbook.

```sh
ansible-playbook sysengquick.k3s.deploy_k3s
```

### Deploying Rancher to Your Cluster

Once your cluster is up, the final step is to deploy rancher.

#### Configure the rancher Role Defaults

Take a look at the rancher role defaults.
Open `main.yml` in _collections/sysengquick/k3s/roles/rancher/defaults_.

##### rancher_bootstrap_password

This is the password used to connect to rancher the first time.
You should change this after installation, so the bootstrap password isn't really important.

##### rancher_cert_manager_version

This is the version of cert-manager to install.

##### rancher_debug

Similar to k3sup_debug.
Displays command module output after commands run by the playbooks.

##### rancher_hostname

This is the default hostname of your rancher UI.
You can change this later, but it might be easier to change it here.

##### rancher_lb_service_enable

Set to true if you want to use a service loadbalancer.
This might be useful if you disable the default traefik in k3s.

##### rancher_lb_service_name

This is the name of the service loadbalancer if enabled.

##### rancher_replicas

This is how many rancher replicas to run.
3 is a good default for an HA deployment.

##### rancher_version

This is the version of rancher to install.
Ensure you pick a version compatible with your selected k3s version.

#### deploy_rancher playbook

After you've gone through the defaults, run the deploy_rancher playbook.

```sh
ansible-playbook sysengquick.k3s.deploy_rancher
```

## Additional Resources

Check out the YouTube playlist in the YouTube Series link at the top.

If you need help or something isn't working, file an issue on the github repo.
