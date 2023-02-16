#!/bin/bash

#oml_nic=ens18
#oml_app_host=172.16.101.42
#oml_obs_host=172.16.101.43
#oml_pgsql_host=172.16.101.42
#oml_pgsql_port=5432
#oml_pgsql_user=omnileads
#oml_pgsql_password=omnileads
#oml_ami_user=omnileads
#oml_ami_password=omnileads
#oml_callrec_device=s3
#s3_bucket_name=omnileads

PRIVATE_IPV4=$(ip addr show ${oml_nic} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
PUBLIC_IPV4=$(curl ifconfig.co)

echo "******************** update and install packages ********************"

apt update
apt install -y ansible git curl

echo "******************** git clone omnileads repo ********************"

cd /usr/src
git clone --branch ${oml_deploytool_branch} https://gitlab.com/omnileads/omldeploytool
cd omldeploytool/ansible

# echo "******************************************* config and install *****************************************"
# echo "******************************************* config and install *****************************************"
# echo "******************************************* config and install *****************************************"

sed -i "s/asterisk_version:/asterisk_version: ${oml_acd_release}/g" ./inventory_voice.yml

sed -i "s%\TZ:%TZ: ${oml_tz}%g" ./inventory_voice.yml
sed -i "s/omni_ip_lan:/omni_ip_lan: $PRIVATE_IPV4/g" ./inventory_voice.yml
sed -i "s/voice_host:/voice_host: $PRIVATE_IPV4/g" ./inventory_voice.yml
sed -i "s/application_host:/application_host: ${oml_app_host}/g" ./inventory_voice.yml
sed -i "s/observability_host:/observability_host: ${oml_observability_host}/g" ./inventory_voice.yml
sed -i "s/#redis_host:/redis_host: ${oml_redis_host}/g" ./inventory_voice.yml
sed -i "s/postgres_host:/postgres_host: ${oml_pgsql_host}/g" ./inventory_voice.yml
sed -i "s/postgres_port:/postgres_port: ${oml_pgsql_port}/g" ./inventory_voice.yml
sed -i "s/postgres_database:/postgres_database: ${oml_pgsql_db}/g" ./inventory_voice.yml
sed -i "s/postgres_user:/postgres_user: ${oml_pgsql_user}/g" ./inventory_voice.yml
sed -i "s/postgres_password:/postgres_password: ${oml_pgsql_password}/g" ./inventory_voice.yml
sed -i "s/ami_user:/ami_user: ${oml_ami_user}/g" ./inventory_voice.yml
sed -i "s/ami_password:/ami_password: ${oml_ami_password}/g" ./inventory_voice.yml
sed -i "s/callrec_device:/callrec_device: ${oml_callrec_device}/g" ./inventory_voice.yml

sed -i "s/bucket_name:/bucket_name: ${s3_bucket_name}/g" ./inventory_voice.yml
sed -i "s/bucket_url:/bucket_url: aws/g" ./inventory_voice.yml

if [[ "${aws_region}" != "NULL" ]];then
    sed -i "s/bucket_region: us-east-1/bucket_region: ${aws_region}/g" ./inventory_voice.yml
fi


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
  --tags asterisk \
  -i inventory_voice.yml