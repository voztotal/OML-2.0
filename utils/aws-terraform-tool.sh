#!/bin/bash

# script de deploy de OMniLeads-AWS-Terraform tool 
# SO: Ubuntu 20.04 fresh-install
# ATENCION: antes de ejecutar debera contar con la clave ssh de este host habilitada en su cuenta GIT.

USER_DOCKER=fts 
TERRAFORM_REPO=https://gitlab.com/omnileads/terraform-aws.git
TENANTS_REPO=git@gitlab.com:....

apt-get update

apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88

add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io

systemctl enable docker.service
systemctl enable containerd.service
systemctl start docker.service
systemctl start containerd.service

curl -L "https://github.com/docker/compose/releases/download/1.28.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

adduser $USER_DOCKER
usermod -aG docker $USER_DOCKER
cd /home/$USER_DOCKER 
git clone $TERRAFORM_REPO terraform
chown $USER_DOCKER -R terraform
cd /home/$USER_DOCKER/terraform 
git clone $TENANTS_REPO instances

reboot