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
echo "******************** update and install packages ********************"
echo "******************** update and install packages ********************"

apt update
apt install -y ansible git curl

echo "******************** git clone omnileads repo ********************"
echo "******************** git clone omnileads repo ********************"
echo "******************** git clone omnileads repo ********************"

cd /usr/src
git clone --branch ${oml_deploytool_branch} https://gitlab.com/omnileads/omldeploytool
cd omldeploytool/ansible

echo "******************************************* config and install *****************************************"
echo "******************************************* config and install *****************************************"
echo "******************************************* config and install *****************************************"

sed -i "s/enterprise_edition/enterprise_edition/g" ./inventory_app.yml

sed -i "s/omnileads_version:/omnileads_version: ${oml_app_release}/g" ./inventory_app.yml
sed -i "s/websockets_version:/websockets_version: ${oml_websockets_release}/g" ./inventory_app.yml
sed -i "s/nginx_version:/nginx_version: ${oml_nginx_release}/g" ./inventory_app.yml
sed -i "s/kamailio_version:/kamailio_version: ${oml_kamailio_release}/g" ./inventory_app.yml

sed -i "s%\TZ:%TZ: ${oml_tz}%g" ./inventory_app.yml
sed -i "s/omni_ip_lan:/omni_ip_lan: $PRIVATE_IPV4/g" ./inventory_app.yml
sed -i "s/voice_host:/voice_host: ${oml_acd_host}/g" ./inventory_app.yml
sed -i "s/application_host:/application_host: $PRIVATE_IPV4/g" ./inventory_app.yml
sed -i "s/observability_host:/observability_host: ${oml_observability_host}/g" ./inventory_app.yml
sed -i "s/postgres_host:/postgres_host: ${oml_pgsql_host}/g" ./inventory_app.yml
sed -i "s/#redis_host:/redis_host: ${oml_redis_host}/g" ./inventory_app.yml
sed -i "s/postgres_port:/postgres_port: ${oml_pgsql_port}/g" ./inventory_app.yml
sed -i "s/postgres_database:/postgres_database: ${oml_pgsql_db}/g" ./inventory_app.yml
sed -i "s/postgres_user:/postgres_user: ${oml_pgsql_user}/g" ./inventory_app.yml
sed -i "s/postgres_password:/postgres_password: ${oml_pgsql_password}/g" ./inventory_app.yml
sed -i "s/ami_user:/ami_user: ${oml_ami_user}/g" ./inventory_app.yml
sed -i "s/ami_password:/ami_password: ${oml_ami_password}/g" ./inventory_app.yml
sed -i "s/callrec_device:/callrec_device: ${oml_callrec_device}/g" ./inventory_app.yml

echo "access KEY: ${oml_s3_access_key}"
echo "secret KEY: ${oml_s3_secret_key}"
sleep 10

sed -i "s/bucket_access_key:/bucket_access_key: ${oml_s3_access_key}/g" ./inventory_app.yml
sed -i "s/bucket_secret_key:/bucket_secret_key: ${oml_s3_secret_key}/g" ./inventory_app.yml

sed -i "s/bucket_name:/bucket_name: ${s3_bucket_name}/g" ./inventory_app.yml
sed -i "s/bucket_url:/bucket_url: aws/g" ./inventory_app.yml

if [[ "${aws_region}" != "NULL" ]];then
    sed -i "s/bucket_region: us-east-1/bucket_region: ${aws_region}/g" ./inventory_app.yml
fi

# # Wombat Dialer parameters *******
if [[ "${api_dialer_user}"  != "NULL" ]];then
  sed -i "s/dialer_user:/dialer_user: ${api_dialer_user}/g" ./inventory_app.yml
fi
if [[ "${api_dialer_password}"  != "NULL" ]];then
  sed -i "s/dialer_password:/dialer_password: ${api_dialer_password}/g" ./inventory_app.yml
fi
if [[ "${oml_dialer_host}" != "NULL" ]];then
  sed -i "s/dialer_host:/dialer_host: ${oml_dialer_host}/g" ./inventory_app.yml
fi

sed -i "s/#rtpengine_host:/rtpengine_host: ${oml_rtpengine_host}/g" ./inventory_app.yml


# if [[ "$${oml_app_sca}" != "NULL" ]];then
#   sed -i "s/sca=3600/sca=${oml_app_sca}/g" ./inventory_app.yml
# fi
# if [[ "${oml_app_ecctl}" != "NULL" ]];then
#   sed -i "s/sca=28800/sca=${oml_app_ecctl}/g" ./inventory_app.yml
# fi
# if [[ "${oml_app_login_fail_limit}" != "NULL" ]];then
#   sed -i "s/LOGIN_FAILURE_LIMIT=10/LOGIN_FAILURE_LIMIT=${oml_app_login_fail_limit}/g" ./inventory_app.yml
# fi

if [ "${oml_google_maps_api_key}" != "NULL" ] && [ "${oml_google_maps_center}" != "NULL" ]; then
    sed -i "s%\google_maps_api_key:%google_maps_api_key: ${oml_google_maps_api_key}%g" ./inventory_app.yml
    sed -i "s%\google_maps_center:%google_maps_center: ${oml_google_maps_center}%g" ./inventory_app.yml
fi

if [[ "${oml_upgrade_to_major}" != "NULL" ]];then
sed -i "s/#upgrade_from_oml_1/upgrade_from_oml_1/g" ./inventory_app.yml
fi

# sleep 3
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
  observability_repo_path=$(pwd)/components/observability/ \
  rebrand=false \
  tenant_folder=cacanene \
  commit=ascd \
  build_date=\"$(env LC_hosts=C LC_TIME=C date)\"" \
  --tags app \
  -i inventory_app.yml