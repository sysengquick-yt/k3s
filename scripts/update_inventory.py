import os
import yaml

_DEFAULT_PROXMOX_SERVER: str = "proxmox.technoplaza.net"
_DEFAULT_PROXMOX_SSH_USER: str = "ansible"


def main():
    path_prefix: str = ".." if os.getcwd().endswith("/scripts") else "."

    config_path = f"{path_prefix}/collections/sysengquick/k3s/playbooks/group_vars/all/cluster.yml"

    with open(config_path, "r") as f:
        config: dict = yaml.safe_load(f)

    inventory = {
        "all": {
            "children": {
                "proxmox": {
                    "hosts": {
                        config.get("proxmox_server", _DEFAULT_PROXMOX_SERVER): {},
                    },
                    "vars": {
                        "ansible_ssh_user": config.get(
                            "proxmox_ssh_user", _DEFAULT_PROXMOX_SSH_USER
                        ),
                    },
                },
                "k3s": {
                    "children": {
                        "servers": {
                            "hosts": {},
                        },
                        "workers": {"hosts": {}},
                    },
                    "vars": {
                        "ansible_ssh_user": config["node_ssh_user"],
                    },
                },
            },
            "vars": {
                "ansible_ssh_common_args": "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null",
            },
        }
    }

    inventory["all"]["children"]["k3s"]["children"]["servers"]["hosts"] = {
        server["name"]: {"ansible_host": server["ip"]}
        for server in config["cluster_nodes"]["servers"]
    }

    inventory["all"]["children"]["k3s"]["children"]["workers"]["hosts"] = {
        worker["name"]: {"ansible_host": worker["ip"]}
        for worker in config["cluster_nodes"]["workers"]
    }

    inventory_path = f"{path_prefix}/inventory.yaml"

    with open(inventory_path, "w") as f:
        yaml.safe_dump(inventory, f)


if __name__ == "__main__":
    main()
