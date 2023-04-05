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

PRIVATE_IPV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IPV4=$(curl ifconfig.co)

echo "******************** update and install packages ********************"
echo "******************** update and install packages ********************"
echo "******************** update and install packages ********************"

apt update
apt install -y ansible git curl

echo "******************** git clone omnileads repo ********************"
echo "******************** git clone omnileads repo ********************"
echo "******************** git clone omnileads repo ********************"

cd /usr/src
git clone --branch ${oml_deploytool_branch} https://gitlab.com/omnileads/omldeploytool
cd omldeploytool/systemd

echo "******************************************* config and install *****************************************"
echo "******************************************* config and install *****************************************"
echo "******************************************* config and install *****************************************"

sed -i "124,126d" ./inventory.yml 
sed -i "4,13d" ./inventory.yml 

sed -i "s/ansible_host: /ansible_connection: local/g" ./inventory.yml
sed -i "s/omni_ip_lan: /omni_ip_lan: $PRIVATE_IPV4/g" ./inventory.yml

sed -i "s/enterprise_edition: false/enterprise_edition: true/g" ./inventory.yml

sed -i "s/omnileads_version:/omnileads_version: ${oml_app_release}/g" ./inventory.yml
sed -i "s/websockets_version:/websockets_version: ${oml_websockets_release}/g" ./inventory.yml
sed -i "s/nginx_version:/nginx_version: ${oml_nginx_release}/g" ./inventory.yml
sed -i "s/kamailio_version:/kamailio_version: ${oml_kamailio_release}/g" ./inventory.yml

if [[ "${oml_dialer_host}" != "NULL" ]];then
  sed -i "s/dialer_host: /dialer_host: ${oml_dialer_host}/g" ./inventory.yml
fi

sed -i "s/#postgres_host: /postgres_host: ${oml_pgsql_host}/g" ./inventory.yml
sed -i "s/#rtpengine_host:/rtpengine_host: ${oml_rtpengine_host}/g" ./inventory.yml

sed -i "s%\TZ:%TZ: ${oml_tz}%g" ./inventory.yml

sed -i "s/callrec_device: s3/callrec_device: ${oml_callrec_device}/g" ./inventory.yml

sed -i "s/postgres_out: false/postgres_out: true/g" ./inventory.yml
sed -i "s/postgres_port: 5432/postgres_port: ${oml_pgsql_port}/g" ./inventory.yml
sed -i "s/postgres_database: omnileads/postgres_database: ${oml_pgsql_db}/g" ./inventory.yml
sed -i "s/postgres_user: omnileads/postgres_user: ${oml_pgsql_user}/g" ./inventory.yml
sed -i "s/postgres_password: AVNS_XZ1h82JjcV1w_Gyq6XY/postgres_password: ${oml_pgsql_password}/g" ./inventory.yml
sed -i "s/ami_user: omnileads/ami_user: ${oml_ami_user}/g" ./inventory.yml
sed -i "s/ami_password: C12H17N2O4P_o98o98/ami_password: ${oml_ami_password}/g" ./inventory.yml

sed -i "s/bucket_name: omnileads/bucket_name: ${bucket_name}/g" ./inventory.yml
sed -i "s/bucket_access_key: uoHidalFyBdV7BQa/bucket_access_key: ${bucket_access_key}/g" ./inventory.yml
sed -i "s/bucket_secret_key: de5lEoTbU8SbV0cNIdVzOMeCxYw5XbKZ/bucket_secret_key: ${bucket_secret_key}/g" ./inventory.yml
sed -i "s/#bucket_url:/bucket_url: aws/g" ./inventory.yml
if [[ "${aws_region}" != "NULL" ]];then
    sed -i "s/bucket_region: us-east-1/bucket_region: ${aws_region}/g" ./inventory.yml
fi

# # Wombat Dialer parameters *******
if [[ "${api_dialer_user}"  != "NULL" ]];then
  sed -i "s/dialer_user: demoadmin/dialer_user: ${api_dialer_user}/g" ./inventory.yml
fi
if [[ "${api_dialer_password}"  != "NULL" ]];then
  sed -i "s/dialer_password: demo/dialer_password: ${api_dialer_password}/g" ./inventory.yml
fi

if [[ "${oml_app_sca}" != "NULL" ]];then
  sed -i "s/SCA: 3600/SCA: ${oml_app_sca}/g" ./inventory.yml
fi
if [[ "${oml_app_ecctl}" != "NULL" ]];then
  sed -i "s/ECCTL: 28800/ECCTL: ${oml_app_ecctl}/g" ./inventory.yml
fi
# if [[ "${oml_app_login_fail_limit}" != "NULL" ]];then
#   sed -i "s/LOGIN_FAILURE_LIMIT=10/LOGIN_FAILURE_LIMIT=${oml_app_login_fail_limit}/g" ./inventory.yml
# fi

if [ "${oml_google_maps_api_key}" != "NULL" ] && [ "${oml_google_maps_center}" != "NULL" ]; then
    sed -i "s%\google_maps_api_key: NULL%google_maps_api_key: ${oml_google_maps_api_key}%g" ./inventory.yml
fi

if [[ "${oml_upgrade_to_major}" != "NULL" ]];then
sed -i "s/#upgrade_from_oml_1/upgrade_from_oml_1/g" ./inventory.yml
fi

echo "data_host: ${oml_data_host}" >> ./inventory.yml
echo "    voice_host: ${oml_voice_host}" >> ./inventory.yml
echo "    application_host: $PRIVATE_IPV4" >> ./inventory.yml

echo "******************** deploy.sh execution ********************"
echo "******************** deploy.sh execution ********************"
echo "******************** deploy.sh execution ********************"

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
haproxy_repo_path=$(pwd)/components/haproxy/ \
cron_repo_path=$(pwd)/components/cron/ \
sentinel_repo_path=$(pwd)/components/sentinel/ \
daphne_repo_path=$(pwd)/components/daphne/ \
keepalived_repo_path=$(pwd)/components/keepalived/ \
pstn_repo_path=$(pwd)/components/pstn_emulator/ \
addons_repo_path=$(pwd)/components/addons/ \
observability_repo_path=$(pwd)/components/observability/ \
rebrand=false \
tenant_folder=${oml_tenant} \
commit=ascd \
build_date=\"$(env LC_hosts=C LC_TIME=C date)\"" \
--tags app,observability \
-i inventory.yml