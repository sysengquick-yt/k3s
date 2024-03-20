#! /bin/sh

# fix docker volume ownership
sudo chown -R vscode:vscode ~/.kube
sudo chown -R vscode:vscode /bash_history

# ensure k3s vault password file exists
mkdir -p /private/ansible/vault/sysengquick 2>/dev/null
touch -a /private/ansible/vault/sysengquick/k3s
