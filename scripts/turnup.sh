#! /bin/bash

time ansible-playbook sysengquick.k3s.create_cluster
time ansible-playbook sysengquick.k3s.deploy_k3s
time ansible-playbook sysengquick.k3s.deploy_rancher

time kubectl -n cattle-system rollout status deploy/rancher

kubectl get nodes -o wide
kubectl get nodes --all-namespaces -o wide
kubectl -n cattle-system get deploy rancher
