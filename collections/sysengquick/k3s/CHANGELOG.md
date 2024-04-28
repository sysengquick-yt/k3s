# CHANGELOG

## 1.0.2 - 2024-04-28

- add README
- cleanup post create command
- add alma linux 8 cloud image
- template the command paths
- update defaults
- update devcontainer config
- fix typo in turnup script

## 1.0.1 - 2024-03-22

- update ansible-lint
- remove nested ansible_collections directory
- move Dockerfile work directory to /app
- narrow the version of poetry installed in Dockerfile
- move Dockerfile OCI labels to top
- bump docker-compose image version from ghcr
- remove k3s_cp_server inventory group
- fix deploy_k3s play names
- add global_debug flag to override k3sup_debug and rancher_debug
- rename cluster_network to proxmox_network
- template the k3sup local-path argument in k3sup defaults
- add playbook log output

## 1.0.0 - 2024-03-20

- initial release
  - creates proxmox virtual machines
  - installs k3s with k3sup on all cluster nodes
  - deploys kube-vip and kube-vip cloud controller
  - deploys rancher
