#!/bin/bash

src_path="/usr/src"
deploy_tool_path="$src_path/omldeploytool"
inventory_path="$deploy_tool_path/ansible/instances/${oml_tenant}"

PRIVATE_IPV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IPV4=$(curl ifconfig.co)

echo "******************** update and install packages ********************"

apt update
apt install -y ansible git curl

curl -fsSL https://get.docker.com -o ~/get-docker.sh
bash ~/get-docker.sh

echo "******************** git clone omnileads repo ********************"

cd $src_path
git clone --branch ${oml_deploytool_branch} https://gitlab.com/omnileads/omldeploytool
mkdir -p $inventory_path
cp $deploy_tool_path/ansible/inventory.yml $inventory_path/

sed -i "s/ansible_host: 201.22.11.2/ansible_connection: local/g" $inventory_path/inventory.yml
sed -i "s/omni_ip_lan: 10.10.10.3/omni_ip_lan: $PRIVATE_IPV4/g" $inventory_path/inventory.yml

sed -i "43 s/postgres_host:/postgres_host: ${oml_pgsql_host}/g" $inventory_path/inventory.yml
sed -i "44 s/postgres_port:/postgres_port: ${oml_pgsql_port}/g" $inventory_path/inventory.yml
sed -i "45 s/postgres_user:/postgres_user: ${oml_pgsql_user}/g" $inventory_path/inventory.yml
sed -i "46 s/postgres_password:/postgres_password: ${oml_pgsql_password}/g" $inventory_path/inventory.yml
sed -i "47 s/postgres_database: omnileads/postgres_database: ${oml_pgsql_db}/g" $inventory_path/inventory.yml
sed -i "48 s/postgres_maintenance_db: defaultdb/postgres_maintenance_db: postgres/g" $inventory_path/inventory.yml
sed -i "49 s/postgres_ssl: true/postgres_ssl: false/g" $inventory_path/inventory.yml
sed -i "50 s/bucket_access_key:/bucket_access_key: ${bucket_access_key}/g" $inventory_path/inventory.yml
sed -i "51 s/bucket_secret_key:/bucket_secret_key: ${bucket_secret_key}/g" $inventory_path/inventory.yml
sed -i "52 s/bucket_name: tenant_example_3/bucket_name: ${bucket_name}/g" $inventory_path/inventory.yml

sed -i "s/#rtpengine_host:/rtpengine_host: ${oml_rtpengine_host}/g" $inventory_path/inventory.yml
sed -i "s%\#bucket_url: https://sfo3.digitaloceanspaces.com%bucket_url: aws%g" $inventory_path/inventory.yml

sed -i "s%\TZ: America/Argentina/Cordoba%TZ: ${oml_tz}%g" ./inventory.yml

sed -i "s/ami_password:/ami_password: ${oml_ami_password}/g" $inventory_path/inventory.yml
sed -i "s/ami_user: omnileads/ami_user: ${oml_ami_user}/g" $inventory_path/inventory.yml

# sed -i "s/omnileads_version:*/omnileads_version: ${oml_app_release}/g" $inventory_path/inventory.yml
# sed -i "s/websockets_version:*/websockets_version: ${oml_websockets_release}/g" $inventory_path/inventory.yml
# sed -i "s/nginx_version:*/nginx_version: ${oml_nginx_release}/g" $inventory_path/inventory.yml
# sed -i "s/kamailio_version:*/kamailio_version: ${oml_kamailio_release}/g" $inventory_path/inventory.yml

sed -i "s/callrec_device: s3/callrec_device: ${oml_callrec_device}/g" $inventory_path/inventory.yml

sed -i "s/infra_env: cloud/infra_env: lan/g" $inventory_path/inventory.yml

sed -i "s/loki_host: 190.19.150.222/homer_host: ${obs_host}/g" $inventory_path/inventory.yml
sed -i "s/homer_host: 190.19.150.222/homer_host: ${obs_host}/g" $inventory_path/inventory.yml

if [[ "${aws_region}" != "NULL" ]];then
    sed -i "s/bucket_region: us-east-1/bucket_region: ${aws_region}/g" $inventory_path/inventory.yml
fi

# # Wombat Dialer parameters *******
if [[ "${api_dialer_user}"  != "NULL" ]];then
  sed -i "s/dialer_user: demoadmin/dialer_user: ${api_dialer_user}/g" $inventory_path/inventory.yml
fi
if [[ "${api_dialer_password}"  != "NULL" ]];then
  sed -i "s/dialer_password: demo/dialer_password: ${api_dialer_password}/g" $inventory_path/inventory.yml
fi

if [[ "${oml_app_sca}" != "NULL" ]];then
  sed -i "s/SCA: 3600/SCA: ${oml_app_sca}/g" $inventory_path/inventory.yml
fi
if [[ "${oml_app_ecctl}" != "NULL" ]];then
  sed -i "s/ECCTL: 28800/ECCTL: ${oml_app_ecctl}/g" $inventory_path/inventory.yml
fi
# if [[ "${oml_app_login_fail_limit}" != "NULL" ]];then
#   sed -i "s/LOGIN_FAILURE_LIMIT=10/LOGIN_FAILURE_LIMIT=${oml_app_login_fail_limit}/g" $inventory_path/inventory.yml
# fi

if [ "${oml_google_maps_api_key}" != "NULL" ] && [ "${oml_google_maps_center}" != "NULL" ]; then
    sed -i "s%\google_maps_api_key: NULL%google_maps_api_key: ${oml_google_maps_api_key}%g" $inventory_path/inventory.yml
fi

if [[ "${oml_upgrade_to_major}" != "NULL" ]];then
sed -i "s/#upgrade_from_oml_1/upgrade_from_oml_1/g" $inventory_path/inventory.yml
fi

sed -i "220 s/tenant_example_1/#tenant_example_1/g" $inventory_path/inventory.yml
sed -i "222 s/#tenant_example_3/tenant_example_3/g" $inventory_path/inventory.yml
sed -i "226 s/tenant_example_5_data/#tenant_example_5_data/g" $inventory_path/inventory.yml
sed -i "232 s/tenant_example_5_voice/#tenant_example_5_voice/g" $inventory_path/inventory.yml
sed -i "238 s/tenant_example_5_app/#tenant_example_5_app/g" $inventory_path/inventory.yml


cd $deploy_tool_path/ansible
./deploy.sh --action=install --tenant=${oml_tenant}

until curl -sk --head --request GET https://$PRIVATE_IPV4|grep "302" > /dev/null; do echo "Environment still being installed, sleeping 60 seconds"; sleep 60; done; echo "Environment is up"

