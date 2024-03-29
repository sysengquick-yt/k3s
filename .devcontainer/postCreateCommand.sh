#! /bin/sh

UID=$(id -u)

# fix docker created volume permissions
for folder in ~/.kube /bash_history /private
do
    test $(stat -c %u $folder) -ne $UID \
        && sudo chown vscode:vscode $folder
done

VAULT_DIR="/private/ansible-vault"
VAULT_FILE="${VAULT_DIR}/sysengquick-k3s"

mkdir -p ${VAULT_DIR} 2>/dev/null \
    && touch -a ${VAULT_FILE} \
    && chmod 600 ${VAULT_FILE}
