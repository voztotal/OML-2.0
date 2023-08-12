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
sed -i "s/ansible_host: 172.16.101.41/ansible_connection: local/g" $inventory_path/inventory.yml
sed -i "s/omni_ip_lan: 172.16.101.41/omni_ip_lan: $PRIVATE_IPV4/g" $inventory_path/inventory.yml

sed -i "s/data_host: 172.16.101.41/data_host: $PRIVATE_IPV4/g" $inventory_path/inventory.yml

sed -i "236 s/#postgres_host: /postgres_host: ${oml_pgsql_host}/g" $inventory_path/inventory.yml

sed -i "s%\#bucket_url: https://sfo3.digitaloceanspaces.com%bucket_url: aws%g" $inventory_path/inventory.yml

sed -i "s%\TZ: America/Argentina/Cordoba%TZ: ${oml_tz}%g" ./inventory.yml

sed -i "s/infra_env: cloud/infra_env: lan/g" $inventory_path/inventory.yml

sed -i "s/#loki_host: /loki_host: ${oml_obs_host}/g" $inventory_path/inventory.yml
sed -i "s/#homer_host: /homer_host: ${oml_obs_host}/g" $inventory_path/inventory.yml

sed -i "310 s/tenant_example_1/#tenant_example_1/g" $inventory_path/inventory.yml
sed -i "324 s/tenant_example_5_voice/#tenant_example_5_voice/g" $inventory_path/inventory.yml
sed -i "328 s/tenant_example_5_app/#tenant_example_5_app/g" $inventory_path/inventory.yml


cd $deploy_tool_path/ansible
./deploy.sh --action=install --tenant=${oml_tenant}
