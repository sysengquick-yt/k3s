#! /bin/bash

set -euxo pipefail

################################################################################
# COMMENT THIS OUT IF YOU AREN'T USING PROXMOX

time ansible-playbook sysengquick.k3s.create_cluster

################################################################################
# Everything else is for k3s and rancher

time ansible-playbook sysengquick.k3s.deploy_k3s
time ansible-playbook sysengquick.k3s.deploy_rancher

time kubectl -n cattle-system rollout status deploy/rancher

kubectl get nodes -o wide
kubectl get pods --all-namespaces -o wide
kubectl -n cattle-system get deploy rancher
