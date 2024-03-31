#!/bin/bash -xe
# Bootstrap script template to be run on the instance immediately after startup

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

    # Install system packages
    sudo apt update
    sudo apt install -y python3-pip

    # Installs the bare necessities to run Ansible provisioning locally
    pip install ansible awscli

    # Create a temporary directory
    tempdir=`mktemp -d`
    cd $tempdir

    aws s3 cp "s3://${ bucket_name }/${ server_name }/ansible.tgz" .
    tar -zxvf ansible.tgz

    cd ansible
    ansible-playbook provision.yml
