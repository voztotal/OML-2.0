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
#export oml_nic=eth0

# Component gitlab branch
#export oml_ws_release=master
#export oml_ws_port=8000

# ---- In case of simple REDIS node (redis://redis_host:redis_port)
# ---- In case of REDIS cluster (redis+sentinel://master/sentinel_host_01,sentinel_host_02,sentinel_host_03)
#export oml_redis_host=
#export oml_redis_port=

# ---- Websockets settings when REDIS was deployed like cluster
#export oml_redis_cluster=true
#export oml_redis_sentinel_host_01=
#export oml_redis_sentinel_host_02=
#export oml_redis_sentinel_host_03=

# *********************************** SET ENV VARS **************************************************
# *********************************** SET ENV VARS **************************************************

SRC=/usr/src
COMPONENT_REPO=https://gitlab.com/omnileads/omnileads-websockets.git
COMPONENT_REPO_DIR=omwebsockets

apt update && apt install -y podman ansible

echo "************************ clone REPO *************************"
echo "************************ clone REPO *************************"
echo "************************ clone REPO *************************"
cd $SRC
git clone $COMPONENT_REPO
cd omnileads-websockets
git checkout ${oml_ws_release}
cd deploy

echo "******************** Install websocket ***************************"
echo "******************** Install websocket ***************************"
echo "******************** Install websocket ***************************"
sed -i "s/redis_host=/redis_host=${oml_redis_host}/g" ./inventory
sed -i "s/redis_port=/redis_port=${oml_redis_port}/g" ./inventory
sed -i "s/websocket_port=8000/websocket_port=${oml_ws_port}/g" ./inventory

if [[ "${oml_redis_cluster}" == "true" ]];then
sed -i "s/#redis_ha=true/redis_ha=true/g" ./inventory
sed -i "s/#sentinel_host_01=/sentinel_host_01=${oml_redis_sentinel_host_01}/g" ./inventory
sed -i "s/#sentinel_host_02=/sentinel_host_02=${oml_redis_sentinel_host_02}/g" ./inventory
sed -i "s/#sentinel_host_03=/sentinel_host_03=${oml_redis_sentinel_host_03}/g" ./inventory
fi
sed -i "s/#redis_ha=true/redis_ha=false/g" ./inventory

ansible-playbook websockets.yml -i inventory --extra-vars "websockets_version=$(cat ../.websockets_version)"
