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
# *********************************** SET ENV VARS **************************************************

# The infrastructure environment:
# onpremise | digitalocean | linode | vultr
#export oml_infras_stage=onpremise

# Set your net interfaces, you must have at least a PRIVATE_NIC
# The public interface is not mandatory, if you don't have it, you can leave it blank
#export oml_nic=eth1
#export oml_public_nic=eth0

# Component gitlab branch
#export oml_rtpengine_release=210629.01

########################################## STAGE #######################################
# You must to define your scenario to deploy RTPEngine
# LAN if all agents work on LAN netwrok or VPN
# CLOUD if all agents work from the WAN
# HYBRID_1_NIC if some agents work on LAN and others from WAN and the host have ony 1 NIC
# HYBRID_2_NIC if some agents work on LAN and others from WAN and the host have 2 NICs
# (1 NIC for LAN IPADDR and 1 NIC for WAN IPADDR)
#export oml_type_deploy=

# *********************************** SET ENV VARS **************************************************
# *********************************** SET ENV VARS **************************************************
SSM_AGENT_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"

COMPONENT_REPO_URL=https://gitlab.com/omnileads/omlrtpengine.git
COMPONENT_REPO_DIR=omlrtpengine
SRC=/usr/src

echo "******************** prereq packages ***************************"
echo "******************** prereq packages ***************************"
yum -y update
yum -y install git python3-pip python3 kernel-devel curl

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
    PRIVATE_IPV4=$(ip addr show ${oml_nic} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
    if [ ${oml_public_nic} ]; then
      PUBLIC_IPV4=$(ip addr show ${oml_public_nic} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
    else
      PUBLIC_IPV4=$(curl ifconfig.co)
    fi
    ;;
  aws)
    echo -n "AWS"
    PRIVATE_IPV4=$(ip addr show ${oml_nic} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
    PUBLIC_IPV4=$(curl checkip.amazonaws.com)
    amazon-linux-extras install epel
    ;;  
  *)
    echo -n "************ [ERROR] you must to declare STAGE variable ***********"
    echo -n "************ [ERROR] you must to declare STAGE variable ***********"
    echo -n "************ [ERROR] you must to declare STAGE variable ***********"
    sleep 60
    ;;
esac

echo "******************** prereq selinux and firewalld ***************************"
echo "******************** prereq selinux and firewalld ***************************"
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux > /dev/null 2>&1
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config > /dev/null 2>&1
setenforce 0
systemctl disable firewalld > /dev/null 2>&1
systemctl stop firewalld > /dev/null 2>&1

echo "************************* ansible install ***********************************"
echo "************************* ansible install ***********************************"
pip3 install --trusted-host pypi.python.org pip --upgrade
pip3 install 'ansible==2.9.2'
export PATH="$HOME/.local/bin/:$PATH"

echo "************************ Clone repo and run component install  *************************"
echo "************************ Clone repo and run component install  *************************"
cd $SRC
git clone $COMPONENT_REPO_URL
cd $COMPONENT_REPO_DIR
git checkout ${oml_rtpengine_release}
cd deploy

ansible-playbook rtpengine.yml -i inventory --extra-vars "rtpengine_version=$(cat ../.rtpengine_version)"

echo "******************** Overwrite rtpengine.conf ***************************"
echo "******************** Overwrite rtpengine.conf ***************************"
case ${oml_type_deploy} in
  CLOUD)
    echo -n "***** CLOUD rtpengine"
    echo "OPTIONS="-i $PUBLIC_IPV4  -o 60 -a 3600 -d 30 -s 120 -n $PRIVATE_IPV4:22222 -m 20000 -M 50000 -L 7 --log-facility=local1""  > /etc/rtpengine-config.conf
    ;;
  LAN)
    echo -n "***** LAN rtpengine"
    echo "OPTIONS="-i $PRIVATE_IPV4  -o 60 -a 3600 -d 30 -s 120 -n $PRIVATE_IPV4:22222 -m 20000 -M 50000 -L 7 --log-facility=local1""  > /etc/rtpengine-config.conf
    ;;
  HYBRID_1_NIC)
    echo -n "***** CLOUD or LAN users of rtpengine with 1 NIC"
    echo "OPTIONS="-i $PRIVATE_IPV4!$PUBLIC_IPV4  -o 60 -a 3600 -d 30 -s 120 -n $PRIVATE_IPV4:22222 -m 20000 -M 50000 -L 7 --log-facility=local1""  > /etc/rtpengine-config.conf
    ;;
  HYBRID_2_NIC)
    echo -n "***** CLOUD or LAN users of rtpengine with public and private NIC"
    echo "OPTIONS="-i internal/$PRIVATE_IPV4!external/$PUBLIC_IPV4  -o 60 -a 3600 -d 30 -s 120 -n $PRIVATE_IPV4:22222 -m 20000 -M 50000 -L 7 --log-facility=local1""  > /etc/rtpengine-config.conf
    ;;
  *)
    echo " ************** [ERROR] you must to define the STAGE correctly *************"
    echo " ************** [ERROR] you must to define the STAGE correctly *************"
    echo " ************** [ERROR] you must to define the STAGE correctly *************"
    sleep 60
    ;;
esac

echo "******************** Restart rtpengine ***************************"
echo "******************** Restart rtpengine ***************************"
systemctl start rtpengine

echo "************************ Remove source dirs  *************************"
echo "************************ Remove source dirs  *************************"
#rm -rf $SRC/$COMPONENT_REPO_DIR
