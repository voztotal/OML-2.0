#!/bin/bash

echo "************************ install Docker *************************"
echo "************************ install Docker *************************"
echo "************************ install Docker *************************"

SSM_AGENT_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"

SRC=/usr/src
COMPONENT_REPO=https://gitlab.com/omnileads/omnileads-websockets.git
COMPONENT_REPO_DIR=omwebsockets

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

echo "************************ Clone REPO *************************"
echo "************************ Clone REPO *************************"
echo "************************ Clone REPO *************************"
cd $SRC
git clone $COMPONENT_REPO
cd omnileads-websockets
git checkout ${oml_ws_release}
cd deploy
docker-compose up -d
