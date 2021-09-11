#!/bin/bash

########################## README ############ README ############# README #########################
########################## README ############ README ############# README #########################
# El script first_boot_installer tiene como finalidad desplegar el componente sobre una instancia 
# de linux exclusiva. Las variables que utiliza son "variables de entorno" de la instancia que está
# por lanzar el script como acto seguido al primer boot del sistema operativo.
# Dichas variables podrán ser provisionadas por un archivo .env (ej: Vagrant) o bien utilizando este 
# script como plantilla de terraform. 
#
# En el caso de necesitar ejecutar este script manualmente sobre el user_data de una instancia cloud
# o bien sobre una instancia onpremise a través de una conexión ssh, entonces se deberá copiar
# esta plantilla hacia un archivo ignorado por git: first_boot_installer.sh para luego sobre 
# dicha copia descomentar las líneas que comienzan con la cadena "export" para posteriormente 
# introducir el valor deseado a cada variable.
########################## README ############ README ############# README #########################
########################## README ############ README ############# README #########################

# *********************************** SET ENV VARS **************************************************
# The infrastructure environment:
# onpremise | digitalocean | linode | vultr
#export oml_infras_stage=onpremise

# Set your net interfaces, you must have at least a PRIVATE_NIC
#export oml_nic=eth1

# Component gitlab branch
#export oml_redis_release=210624.01
# *********************************** SET ENV VARS **************************************************

SSM_AGENT_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"

SRC=/usr/src
COMPONENT_REPO=https://gitlab.com/omnileads/omlredis.git
REDIS_PORT=6379

echo "******************** IPV4 address config ***************************"
echo "******************** IPV4 address config ***************************"
case ${oml_infras_stage} in
  digitalocean)
    echo -n "DigitalOcean"
    PUBLIC_IPV4=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
    PRIVATE_IPV4=$(curl -s http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
    ;;
  linode)
    echo -n "Linode"
    PRIVATE_IPV4=$(ip addr show $NIC |grep "inet 192.168" |awk '{print $2}' | cut -d/ -f1)
    PUBLIC_IPV4=$(curl checkip.amazonaws.com)
    ;;
  onpremise)
    echo -n "Onpremise CentOS7 Minimal"
    PRIVATE_IPV4=$(ip addr show ${oml_nic} | grep inet |grep -v inet6 | awk '{print $2}' | cut -d/ -f1)
    ;;
  aws)
    echo -n "AWS"
    PRIVATE_IPV4=$(ip addr show ${oml_nic} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
    PUBLIC_IPV4=$(curl checkip.amazonaws.com)
    ;;    
  *)
    echo -n "you must to declare STAGE variable"
    ;;
esac

echo "************************ disable SElinux & firewalld *************************"
echo "************************ disable SElinux & firewalld *************************"
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0
systemctl disable firewalld > /dev/null 2>&1
systemctl stop firewalld > /dev/null 2>&1

echo "************************ yum install  *************************"
echo "************************ yum install  *************************"
case ${oml_infras_stage} in
  aws)
    amazon-linux-extras install -y epel
    yum install -y $SSM_AGENT_URL
    yum install -y git python3-pip patch libedit-devel libuuid-devel
    systemctl start amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    ;;
  *)
    yum update -y
    yum -y install git python3 python3-pip kernel-devel
    ;;
esac

echo "************************ install ansible *************************"
echo "************************ install ansible *************************"
echo "************************ install ansible *************************"
pip3 install pip --upgrade
pip3 install 'ansible==2.9.2'
export PATH="$HOME/.local/bin/:$PATH"

echo "************************ clone REPO *************************"
echo "************************ clone REPO *************************"
echo "************************ clone REPO *************************"
cd $SRC
git clone $COMPONENT_REPO
cd omlredis
git checkout ${oml_redis_release}
cd deploy

echo "************************ config and install *************************"
echo "************************ config and install *************************"
echo "************************ config and install *************************"
ansible-playbook redis.yml -i inventory --extra-vars "redis_version=$(cat ../.redis_version) redisgears_version=$(cat ../.redisgears_version)"

sed -i "s/#bind/bind $PRIVATE_IPV4/g" /etc/redis.conf
sed -i "s/port 6379/port $REDIS_PORT/g" /etc/redis.conf

systemctl restart redis