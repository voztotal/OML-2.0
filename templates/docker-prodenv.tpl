#!/bin/bash

SSM_AGENT_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"
MYSQL_CLIENT_URL="https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm"
INTERNAL_IP=$(default_if=$(ip route show | awk '/^default/ {print $5}'); ifconfig $default_if | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
DOCKER_PATH="/home/ec2-user/${customer}"
ANSIBLE_ENVARS="admin_pass=${django_pass} \
  ami_user=${ami_user} \
  ami_password=${ami_password} \
  ast_builded_image=freetechsolutions/asterisk:\$${RELEASE} \
  asterisk_fqdn=asterisk \
  ast_sip_port=5160 \
  cert=cert.pem \
  customer=${customer} \
  deploy_location=$DOCKER_PATH \
  devenv=0 \
  dialer_builded_image=freetechsolutions/dialer:\$${DIALER_VERSION} \
  dialer_fqdn=dialer \
  dialer_user=${dialer_user} \
  dialer_password=${dialer_password} \
  ECCTL=${ECCTL} \
  is_docker=true \
  kamailio_builded_image=freetechsolutions/kamailio:\$${RELEASE} \
  kamailio_fqdn=kamailio \
  kam_sip_port=5060 \
  kam_tls_port=5061 \
  kam_ws_port=1080 \
  kam_wss_port=14443 \
  key=key.pem \
  mariadb_fqdn=${mysql_host} \
  MONITORFORMAT=mp3 \
  mysql_root_password=${default_mysql_password} \
  nginx_builded_image=freetechsolutions/nginx:\$${RELEASE} \
  nginx_fqdn=nginx \
  nginx_external_port=443 \
  omniapp_builded_image=freetechsolutions/omniapp:\$${RELEASE} \
  oml_release=${omnileads_release} \
  omni_fqdn=${alb_host} \
  omni_ip=$INTERNAL_IP \
  omniapp_fqdn=omniapp \
  postgres_database=${customer_pg_database} \
  postgresql_fqdn=${pg_host} \
  postgres_user=${customer_pg_username} \
  postgres_password=${customer_pg_password} \
  prodenv=1 \
  redis_image=redis:5-alpine \
  redis_fqdn=redis \
  rtp_finish_port=50000 \
  rtp_start_port=40000 \
  rtpengine_port=22222 \
  SCA=${SCA} \
  schedule=${schedule} \
  subnet=192.168.15.0/24 \
  subnet_name=prod_net \
  TZ=America/Argentina/Cordoba \
  usuario=ec2-user \
  version=${omnileads_release} \
  wd_external_port=442 \
  wombat_version=${wombat_version}"

echo "Instalando docker y postgresql11-client"
amazon-linux-extras install docker postgresql11
service docker start
usermod -a -G docker ec2-user
chkconfig docker on

echo "Instalando docker-compose"
curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin

echo "Instalando amazon-ssm-agent, pip y mysql-client"
yum install -y $MYSQL_CLIENT_URL
yum install -y $SSM_AGENT_URL python-pip mysql-community-client
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

echo "Instalando Ansible"
pip install 'ansible==2.9.2'

echo "Clonando el repositorio  de omnileads"
yum install git -y
cd /var/tmp/
git clone https://gitlab.com/omnileads/ominicontacto.git
cd ominicontacto && git checkout develop

echo "Creando directorio de certificados"
mkdir -p $DOCKER_PATH/certs

echo "Ejecutando las tasks de renderizado de templates necesarios para prodenv"
cd deploy/ansible

echo "Renderizando .env file"
ansible 127.0.0.1 \
  -m template \
  -a "src=roles/docker/files/docker_compose_files/.env dest=$DOCKER_PATH" \
  -e "$ANSIBLE_ENVARS"

echo "Renderizando docker-compose file"
ansible 127.0.0.1 \
  -m template \
  -a "src=roles/docker/files/docker_compose_files/docker-compose.yml dest=$DOCKER_PATH" \
  -e "$ANSIBLE_ENVARS"

echo "Renderizando kamailio-local.cfg"
ansible 127.0.0.1 \
  -m template \
  -a "src=roles/kamailio/templates/etc/kamailio-local.cfg dest=$DOCKER_PATH" \
  -e "$ANSIBLE_ENVARS"

echo "Renderizando omnileads-prodenv service"
ansible 127.0.0.1 \
  -m template \
  -a "src=roles/docker/files/systemd/omnileads.service dest=/etc/systemd/system/omnileads-{{ customer }}.service" \
  -e "$ANSIBLE_ENVARS"

echo "Renderizando postinstall.sh"
ansible 127.0.0.1 \
  -m template \
  -a "src=roles/docker/files/scripts/postinstall.sh dest=$DOCKER_PATH variable_start_string='[[' variable_end_string=']]'" \
  -e "$ANSIBLE_ENVARS"

echo "Renderizando odbc.ini file"
ansible 127.0.0.1 \
  -m template \
  -a "src=roles/asterisk/templates/etc/odbc.ini dest=$DOCKER_PATH" \
  -e "$ANSIBLE_ENVARS"

echo "Renderizando oml_res_odbc.conf file"
ansible 127.0.0.1 \
  -m template \
  -a "src=roles/asterisk/templates/conf/oml_res_odbc.conf dest=$DOCKER_PATH" \
  -e "$ANSIBLE_ENVARS"

echo "Modificando línea del kamailio-local.cfg para RTPENGINE_HOST"
sed -i "s/$INTERNAL_IP/${rtpengine_host}/g" $DOCKER_PATH/kamailio-local.cfg

echo "Modificando variables WOMBAT_DB, WOMBAT_DB_USER y WOMBAT_DB_PASS del .env"
sed -i "s/WOMBAT_DB=wombat/WOMBAT_DB=${customer_mysql_database}/g" $DOCKER_PATH/.env
sed -i "s/WOMBAT_DB_USER=wombat/WOMBAT_DB_USER=${customer_mysql_username}/g" $DOCKER_PATH/.env
sed -i "s/WOMBAT_DB_PASS=dials/WOMBAT_DB_PASS=${customer_mysql_password}/g" $DOCKER_PATH/.env

echo "Creando los certificados para los servicios"
cd $DOCKER_PATH/certs
subj="
C=AR
ST=CBA
O=CBA
localityName=FTS
commonName=*.fts-cloud.net
organizationalUnitName=Desarrollo
emailAddress=desarrollo@freetechsolutions.com.ar
"
openssl req -x509 -newkey rsa:4096 -nodes -out cert.pem -keyout key.pem -days 365  -subj "$(echo -n "$subj" | tr "\n" "/")"

set -e

echo "Ejecutando tareas de creacion de base de datos postgres y user de cliente"
until PGPASSWORD=${default_pg_password} psql -h ${pg_host} -U ${default_pg_username} -d ${default_pg_database} -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done
if  PGPASSWORD=${default_pg_password} psql -h ${pg_host} -U ${default_pg_username} -c "\l" |grep -w "${customer_pg_database}"; then
  echo "Postgresql actions already executed"
else
    echo "Creating postgresql user/database"
    PGPASSWORD=${default_pg_password} psql -h ${pg_host} -U ${default_pg_username} -c "create database ${customer_pg_database};"
    PGPASSWORD=${default_pg_password} psql -h ${pg_host} -U ${default_pg_username} -c "create user ${customer_pg_username} with encrypted password '${customer_pg_password}';"
    PGPASSWORD=${default_pg_password} psql -h ${pg_host} -U ${default_pg_username} -c "grant all privileges on database ${customer_pg_database} to ${customer_pg_username};"
    echo "Adding extension plperl"
    PGPASSWORD=${default_pg_password} psql -d ${customer_pg_database} -U ${default_pg_username} -h ${pg_host} -c "CREATE EXTENSION plperl;"
fi

echo "Ejecutando tareas de creacion de base de datos mysql y user de cliente"
if  MYSQL_PWD=${default_mysql_password} mysql -h ${mysql_host} -u ${default_mysql_username} -e "show databases;" |grep -w "${customer_mysql_database}"; then
  echo "MYSQL actions already executed"
else
  echo "Running mysql configuration steps"
  MYSQL_PWD=${default_mysql_password} mysql -h ${mysql_host} -u ${default_mysql_username} -e "GRANT SELECT,CREATE,UPDATE,DROP,INSERT,LOCK TABLES ON *.* TO '${customer_mysql_username}'@'%' IDENTIFIED BY '${customer_mysql_password}' WITH GRANT OPTION;"
fi

echo "Iniciando el servicio omnileads-${customer}"
chown -R ec2-user.ec2-user $DOCKER_PATH
systemctl daemon-reload
systemctl enable omnileads-${customer}
systemctl start omnileads-${customer}
