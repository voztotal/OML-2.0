#!/bin/bash

PRIVATE_IPV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IPV4=$(curl ifconfig.co)

echo "******************** update and install packages ********************"

apt update
apt install -y ansible git curl

echo "******************** git clone omnileads repo ********************"

cd /usr/src
git clone --branch ${oml_deploytool_branch} https://gitlab.com/omnileads/omldeploytool
cd omldeploytool/systemd

# echo "******************************************* config and install *****************************************"
# echo "******************************************* config and install *****************************************"
# echo "******************************************* config and install *****************************************"

sed -i "124,126d" ./inventory.yml 
sed -i "9,18d" ./inventory.yml 

sed -i "s/ansible_host: /ansible_connection: local/g" ./inventory.yml
sed -i "s/omni_ip_lan: /omni_ip_lan: $PRIVATE_IPV4/g" ./inventory.yml

sed -i "s%\TZ:%TZ: ${oml_tz}%g" ./inventory.yml

echo "data_host: $PRIVATE_IPV4" >> ./inventory.yml
echo "    voice_host: ${oml_voice_host}" >> ./inventory.yml
echo "    application_host: ${oml_app_host}" >> ./inventory.yml

ansible-playbook matrix.yml --extra-vars \
  "django_repo_path=$(pwd)/components/django/ \
  redis_repo_path=$(pwd)/components/redis/ \
  pgsql_repo_path=$(pwd)/components/postgresql/ \
  kamailio_repo_path=$(pwd)/components/kamailio/ \
  asterisk_repo_path=$(pwd)/components/asterisk/ \
  rtpengine_repo_path=$(pwd)/components/rtpengine/ \
  websockets_repo_path=$(pwd)/components/websockets/ \
  nginx_repo_path=$(pwd)/components/nginx/ \
  minio_repo_path=$(pwd)/components/minio/ \
  observability_repo_path=$(pwd)/components/observability/ \
  rebrand=false \
  tenant_folder=${oml_tenant} \
  commit=ascd \
  build_date=\"$(env LC_hosts=C LC_TIME=C date)\"" \
  --tags redis,observability \
  -i inventory.yml