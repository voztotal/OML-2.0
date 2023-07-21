#!/bin/bash

src_path="/usr/src"
deploy_tool_path="$src_path/omldeploytool"
inventory_path="$deploy_tool_path/ansible/instances/${oml_tenant}"

PRIVATE_IPV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IPV4=$(curl ifconfig.co)

echo "******************** update and install packages ********************"

apt update
apt install -y ansible git curl

echo "******************** git clone omnileads repo ********************"

cd $src_path
git clone --branch ${oml_deploytool_branch} https://gitlab.com/omnileads/omldeploytool
mkdir -p $inventory_path
cp $deploy_tool_path/ansible/inventory.yml $inventory_path/

sed -i "s/tenant_id: tenant_example_5/tenant_id: ${oml_tenant}/g" $inventory_path/inventory.yml
sed -i "s/ansible_host: 172.16.101.43/ansible_connection: local/g" $inventory_path/inventory.yml
sed -i "s/omni_ip_lan: 172.16.101.43/omni_ip_lan: $PRIVATE_IPV4/g" $inventory_path/inventory.yml

sed -i "s/data_host: 172.16.101.41/data_host: ${oml_data_host}/g" $inventory_path/inventory.yml
sed -i "s/voice_host: 172.16.101.42/voice_host: ${oml_voice_host}/g" $inventory_path/inventory.yml
sed -i "s/application_host: 172.16.101.43/application_host: $PRIVATE_IPV4/g" $inventory_path/inventory.yml

sed -i "131 s/postgres_user: omnileads/postgres_user: ${oml_pgsql_user}/g" $inventory_path/inventory.yml
sed -i "132 s/postgres_password: HJGKJHGDSAKJHK7856765DASDAS675765JHGJHSAjjhgjhaaa/postgres_password: ${oml_pgsql_password}/g" $inventory_path/inventory.yml
sed -i "133 s/postgres_database: omnileads/postgres_database: ${oml_pgsql_db}/g" $inventory_path/inventory.yml

sed -i "145 s/bucket_access_key: Hghjkdghjkdhasjdasdsada/bucket_access_key: ${bucket_access_key}/g" $inventory_path/inventory.yml
sed -i "146 s/bucket_secret_key: jknkjhkjh4523kjhcksjdhkjfdhKJHHKJGKJh786876876NBVJHB/bucket_secret_key: ${bucket_secret_key}/g" $inventory_path/inventory.yml
sed -i "147 s/bucket_name: omnileads/bucket_name: ${bucket_name}/g" $inventory_path/inventory.yml

sed -i "192 s/#postgres_host:/postgres_host: ${oml_pgsql_host}/g" $inventory_path/inventory.yml

sed -i "s/#rtpengine_host:/rtpengine_host: ${oml_rtpengine_host}/g" $inventory_path/inventory.yml
sed -i "s%\#bucket_url: https://sfo3.digitaloceanspaces.com%bucket_url: aws%g" $inventory_path/inventory.yml

sed -i "s%\TZ: America/Argentina/Cordoba%TZ: ${oml_tz}%g" ./inventory.yml

sed -i "s/ami_password:/ami_password: ${oml_ami_password}/g" $inventory_path/inventory.yml
sed -i "s/ami_user: omnileads/ami_user: ${oml_ami_user}/g" $inventory_path/inventory.yml

sed -i "s/infra_env: cloud/infra_env: lan/g" $inventory_path/inventory.yml

sed -i "s/#loki_host: /loki_host: ${oml_obs_host}/g" $inventory_path/inventory.yml
sed -i "s/#homer_host: /homer_host: ${oml_obs_host}/g" $inventory_path/inventory.yml

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

if [[ "${oml_upgrade_to_major}" != "NULL" ]];then
sed -i "s/#upgrade_from_oml_1/upgrade_from_oml_1/g" $inventory_path/inventory.yml
fi

sed -i "268 s/tenant_example_1/#tenant_example_1/g" $inventory_path/inventory.yml
sed -i "275 s/tenant_example_5_data/#tenant_example_5_data/g" $inventory_path/inventory.yml
sed -i "279 s/tenant_example_5_voice/#tenant_example_5_voice/g" $inventory_path/inventory.yml


if [[ "${oml_app_tag}" != "NULL" ]];then
sed -i "s/#omnileads_version: 1.29.0/omnileads_version: ${oml_app_tag}/g" $inventory_path/inventory.yml
fi

cd $deploy_tool_path/ansible
./deploy.sh --action=install --tenant=${oml_tenant}

until curl -sk --head --request GET https://$PRIVATE_IPV4|grep "302" > /dev/null; do echo "Environment still being installed, sleeping 60 seconds"; sleep 60; done; echo "Environment is up"

