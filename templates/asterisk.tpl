#!/bin/bash

PRIVATE_IPV4=$(ip addr show ${oml_nic} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
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
sed -i "14,18d" ./inventory.yml 
sed -i "4,8d" ./inventory.yml 

sed -i "s/ansible_host: /ansible_connection: local/g" ./inventory.yml
sed -i "s/omni_ip_lan: /omni_ip_lan: $PRIVATE_IPV4/g" ./inventory.yml

sed -i "s/asterisk_version:/asterisk_version: ${oml_acd_release}/g" ./inventory.yml
sed -i "s%\TZ:%TZ: ${oml_tz}%g" ./inventory.yml

sed -i "s/#postgres_host: /postgres_host: ${oml_pgsql_host}/g" ./inventory.yml
sed -i "s/postgres_port: 5432/postgres_port: ${oml_pgsql_port}/g" ./inventory.yml
sed -i "s/postgres_database: omnileads/postgres_database: ${oml_pgsql_db}/g" ./inventory.yml
sed -i "s/postgres_user: omnileads/postgres_user: ${oml_pgsql_user}/g" ./inventory.yml
sed -i "s/postgres_password: AVNS_XZ1h82JjcV1w_Gyq6XY/postgres_password: ${oml_pgsql_password}/g" ./inventory.yml
sed -i "s/ami_user: omnileads/ami_user: ${oml_ami_user}/g" ./inventory.yml
sed -i "s/ami_password: C12H17N2O4P_o98o98/ami_password: ${oml_ami_password}/g" ./inventory.yml
sed -i "s/callrec_device: s3-no-check-cert/callrec_device: ${oml_callrec_device}/g" ./inventory.yml

#sed -i "s%\data_host: \"{{ hostvars['omnileads_data'].omni_ip_lan }}\"%data_host: ${oml_data_host}%g" ./inventory.yml
#sed -i "s%\voice_host: \"{{ hostvars['omnileads_voice'].omni_ip_lan }}\"%voice_host: $PRIVATE_IPV4%g" ./inventory.yml
#sed -i "s%\application_host: \"{{ hostvars['omnileads_app'].omni_ip_lan }}\"%application_host: ${oml_app_host}%g" ./inventory.yml

sed -i "s/bucket_name: omnileads/bucket_name: ${s3_bucket_name}/g" ./inventory.yml
sed -i "s/#bucket_url: https://sfo3.digitaloceanspaces.com/bucket_url: aws/g" ./inventory.yml

if [[ "${aws_region}" != "NULL" ]];then
    sed -i "s/bucket_region: us-east-1/bucket_region: ${aws_region}/g" ./inventory.yml
fi

echo "data_host: ${oml_data_host}" >> ./inventory.yml
echo "    voice_host: $PRIVATE_IPV4" >> ./inventory.yml
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
  --tags asterisk,observability \
  -i inventory.yml