#!/bin/bash

activate() {
  . .venv/bin/activate
}

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
echo "$parent_path"
cd "$parent_path"
activate
cd "ansible"
ansible-playbook bundle.yml
ansible-playbook start.yml
