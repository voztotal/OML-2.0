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

# Set your net interfaces to attach pgsql 5432 port
#export oml_nic=enp0s3

# Component gitlab branch
#export oml_pgsql_release=210629.01

# Postgres db, user & password parameters 
#export oml_db_name=omnileads
#export oml_db_user=omnileads
#export oml_db_password=098098ZZZ

# The device /dev/disk/by-label/dev-name | NULL
#export oml_pgsql_blockdev=NULL

# Use this variables in case of failed install because NIC/IPADDR 
# auto-detection problems
#export PRIVATE_IPV4=192.168.0.100
#export IPADDR_MASK=192.168.0.100/24
# *********************************** SET ENV VARS **************************************************

SSM_AGENT_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"

COMPONENT_REPO=https://gitlab.com/omnileads/omlpgsql.git
SOURCE_DIR=/usr/src
MOUNT_PATH=/var/lib/pgsql

echo "************************ block_device mount *************************"
echo "************************ block_device mount *************************"
if [ ${oml_pgsql_blockdev} != "NULL" ]; then
  mkdir -p MOUNT_PATH
  echo "${oml_pgsql_blockdev} $MOUNT_PATH ext4 defaults,nofail,discard 0 0" | sudo tee -a /etc/fstab
  mount -a
fi

echo "************************ yum install *************************"
echo "************************ yum install *************************"
yum update -y 
yum install -y python3 python3-pip epel-release git ipcalc

echo "******************** IPV4 address config ***************************"
echo "******************** IPV4 address config ***************************"
case ${oml_infras_stage} in
  digitalocean)
    echo -n "DigitalOcean"
     PUBLIC_IPV4=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
     PRIVATE_IPV4=$(curl -s http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address)
     PRIVATE_NETMASK=$(curl -s http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/netmask)
     NETADDR_IPV4=$(ipcalc -n $PRIVATE_IPV4 $PRIVATE_NETMASK |cut -d = -f 2)
     NETMASK_PREFIX=$(ipcalc -p $PRIVATE_IPV4 $PRIVATE_NETMASK |cut -d = -f 2)
    ;;
  linode)
    echo -n "Linode"
     PRIVATE_IPV4=$(ip addr show ${oml_nic} | grep "192.168" | awk '{print $2}' | awk -F/ '{print $1}')
     IPADDR_MASK=$(ip addr show ${oml_nic} | grep "192.168" | awk '{print $2}')
     NETADDR_IPV4=$(ipcalc -n $IPADDR_MASK |cut -d = -f 2)
     NETMASK_PREFIX=$(ip addr show ${oml_nic} | grep "192.168" | awk '{print $2}' | cut -d/ -f2)
    ;;
  onpremise)
    echo "Onpremise CentOS7 Minimal \n"
      if [ -z "$PRIVATE_IPV4" ]; then
        PRIVATE_IPV4=$(ip addr show ${oml_nic} | grep inet |grep -v inet6 | awk '{print $2}' | cut -d/ -f1)
        IPADDR_MASK=$(ip addr show ${oml_nic} | grep inet |grep -v inet6 | awk '{print $2}')
      fi
      NETADDR_IPV4=$(ipcalc -n $IPADDR_MASK |cut -d = -f 2)
      NETMASK_PREFIX=$(ip addr show ${oml_nic} | grep "inet\b" | awk '{print $2}' | cut -d/ -f2)
    ;;
  aws)
    echo -n "AWS"
    PRIVATE_IPV4=$(ip addr show ${oml_nic} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
    IPADDR_MASK=$(ip addr show ${oml_nic} | grep inet |grep -v inet6 | awk '{print $2}')
    NETADDR_IPV4=$(ipcalc -n $IPADDR_MASK |cut -d = -f 2)
    NETMASK_PREFIX=$(ip addr show ${oml_nic} | grep "inet\b" | awk '{print $2}' | cut -d/ -f2)
    amazon-linux-extras install epel
    ;;    
  *)
    echo -n "you must to declare STAGE variable"
    ;;
esac

echo -n "********* NETADDR: $NETADDR_IPV4 ************ NETMASK: $NETMASK_PREFIX \n"
sleep 3

echo "************************ install ansible *************************"
echo "************************ install ansible *************************"
echo "************************ install ansible *************************"
pip3 install pip --upgrade
pip3 install 'ansible==2.9.2'
export PATH="$HOME/.local/bin/:$PATH"

echo "************************ disable SElinux *************************"
echo "************************ disable SElinux *************************"
echo "************************ disable SElinux *************************"
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux > /dev/null 2>&1
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config > /dev/null 2>&1
setenforce 0
systemctl disable firewalld > /dev/null 2>&1
systemctl stop firewalld > /dev/null 2>&1

echo "************************ clone REPO *************************"
echo "************************ clone REPO *************************"
echo "************************ clone REPO *************************"
cd $SOURCE_DIR
git clone $COMPONENT_REPO
cd omlpgsql
git checkout ${oml_pgsql_release}
cd deploy

echo "************************ config and install *************************"
echo "************************ config and install *************************"
echo "************************ config and install *************************"
sed -i "s/postgres_database=my_database/postgres_database=${oml_db_name}/g" ./inventory
sed -i "s/postgres_user=my_user/postgres_user=${oml_db_user}/g" ./inventory
sed -i "s/postgres_password=my_very_strong_pass/postgres_password=${oml_db_password}/g" ./inventory
sed -i "s/subnet=X.X.X.X\/XX/subnet=$NETADDR_IPV4\/$NETMASK_PREFIX/g" ./inventory
sed -i "s/listen_addresses=127.0.0.1/listen_addresses=127.0.0.1,$PRIVATE_IPV4/g" ./inventory

ansible-playbook postgresql.yml -i inventory --extra-vars "postgresql_version=$(cat ../.postgresql_version)"

sleep 5
reboot
