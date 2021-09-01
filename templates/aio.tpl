#!/bin/bash

AWS="/usr/bin/aws"
SSM_AGENT_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"
S3FS="/bin/s3fs"
INSTALL_PREFIX="/opt/omnileads"
ASTERISK_LOCATION="$INSTALL_PREFIX/asterisk"
AWS_REGION=${aws_region}

echo "Instalando amazon-ssm-agent, kernel-devel y git"
amazon-linux-extras install epel
yum install -y $SSM_AGENT_URL kernel-devel git s3fs-fuse

systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

echo "Clonando el repositorio  de omnileads"
cd /var/tmp/
git clone https://${gitlab_user}:${gitlab_password}@${omnileads_repository} ominicontacto
cd ominicontacto && git checkout ${omnileads_release}

echo "Editando el inventory"
python ansible/deploy/edit_inventory.py --self_hosted=yes \
  --admin_password=${django_pass} \
  --ami_user=${ami_user} \
  --ami_password=${ami_password} \
  --dialer_host=${dialer_host} \
  --dialer_user=${dialer_user} \
  --dialer_password=${dialer_password} \
  --ecctl=${ECCTL} \
  --mysql_host=${mysql_host} \
  --postgres_host=${pg_host} \
  --postgres_database=${pg_database} \
  --postgres_user=${pg_username} \
  --postgres_password=${pg_password} \
  --rtpengine_host=${rtpengine_host} \
  --sca=${SCA} \
  --schedule=${schedule} \
  --TZ=${TZ}

echo "Installing python2-pip"
yum install python-pip patch libedit-devel libuuid-devel -y

echo "Instalando ansible"
pip install 'ansible==2.9.2' --user

echo "Ejecutando el deploy.sh"
cd ansible/deploy && ./deploy.sh -i --iface=eth0
sleep 5
if [ -d /usr/local/queuemetrics/ ]; then
  systemctl stop qm-tomcat6 && systemctl disable qm-tomcat6
  systemctl stop mariadb && systemctl disable mariadb
fi

echo "**[omniapp-${customer}] Instalando sngrep"
yum install ncurses-devel make libpcap-devel pcre-devel \
    openssl-devel git gcc autoconf automake -y
cd /root && git clone https://github.com/irontec/sngrep
cd sngrep && ./bootstrap.sh && ./configure && make && make install
ln -s /usr/local/bin/sngrep /usr/bin/sngrep

echo "Ejecutando tareas de monitoreo"
VPS_HOST="www.freetech.com.ar"
VPS_PORT="40404"
SSH_OPTIONS="-o stricthostkeychecking=no -o ConnectTimeout=10"

echo "Instalando openvpn y nagios"
yum install nrpe nagios-plugins-all bc openvpn -y
cd /etc/nagios
sed -i "s/allowed_hosts=127.0.0.1,::1/allowed_hosts=127.0.0.1,10.20.0.1/g" nrpe.cfg
sed -i "s/dont_blame_nrpe=0/dont_blame_nrpe=1/g" nrpe.cfg

if [ ! -d ${mount_path}/monitoring_files ];then
  echo "Creando llave privada para entrar por ssh a VPS"
  mkdir /root/.ssh
  cd ${mount_path}
  cat > id_rsa <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA6GB0lChVeZ/CSBo4eT0Q2RHmNV2XfkfmJbtrtBWr65zQy3h2
VLX7Sg+BcH9m3rjSsQvQlIohmpaWJyS2IfuEizmh+ogICD0r9+faAq8WWAd8o9oo
XTts7QCwYp7nYK/wEHAtuV5WTc7fjKDLdrUpF0qhpPMr7nWsLIVqjD65PKfH0Kd7
wKsjRmFhVYm/VCxtoMRn/8lQNdDMG+PpzEeOVJfzpWnZO9QT/Wk9V81ZD/sUjtpg
EE13ULLicIBV7PbkYMjM+6yDQtFbgT/pBJgTsVdrrKyHJd56hr7v6rix/cMKKLgs
ABzoZTnc4NNDgPmZbU3vM0k/umhx6GXXM3Rc3QIDAQABAoIBAC6H2fAs32i6P8n2
TiagvrXoqqM2+XXU6dXWYKuvxzwnq3uCxJcT1Zyv3Chtqmigs7e1+O81daMh0jFG
XZ4SYikKwk+LW6hir2I1r+bnrl60KRYaQgjhNF+Eys0EqqomsLhp7g33QOrVqNfc
/sDnZ7H9RL7l3n8iWvaTRJGOocLuKBep5c9ljvomgToLX0Kel7KwouQW0h/oPpd/
8EEoWhVxtMrXp9Sw20tZ+4nl+jsAISSJJM0X7sObFN02hCAyTGS4A0yGP/ZhLKo2
dEKXYD5iGL4QNqY1LxmlJB1kdDTa285b/LOL/PsJKGJbVu6XuSrI2bAvbN9oEouV
nbDf6RUCgYEA+HnNNrHBysnitnJmwVGzI64ngzCjaIck80N31VloC9sJToFWUjlL
j15f/IJaqVbiSCWqBzvsNMdt9FseI7T13w3mD7Ov3Yu5v6dRaVxB2qi6D6+RLo4O
jZSih3uMDPYBN2qQXX4hWplae3+dc4vOh1mUREUI34AAMmpI3Zie3ScCgYEA72na
dKHCL7OJRbqbgUwAVa+T6K1TyHSq5qRxeAOqy4kH64icQ3Kme3LTgveijk6E41bJ
l9q+oG+Zn5kho3J/2TxnpS29AOvMqMIDSOEDjV7LEEGtZ/T3A1gNvikNcKpfUNYn
b1GwAni/VyrJ/MmsN2ypIqsfhhORggBN/hn+QFsCgYBz1Jv0jkLv3NMiCAycvBBN
ZscmogrbFH0GJgJ745TcSfx5q1NpOypdKDqIxN+sp0MPLPepLab8J6e7TKqtLJOd
qqX/1dz640Lw8/fArPBKFXO/EjIUyMZB+/MUQ2TTOe7xPW0VGFJGIM0MWz4z+g2K
DRlQBfqP7eSpm+Bh5N7R6wKBgGTOsnBHqCdDtnpIz6+Km914d5QSX2PZVBiXhzuc
d68J/O687+cqgFUcjVjpAmZfQ28iHPI25etR8mKULOjQjmqfF5kigCHCJ8OrJYzr
Sf6dum0W6ngKWnPrAKZgTMtywX2dHq+tuqnfw9llJ/WryTrxIup5GWXwGWWe0Tg8
I6VfAoGBAKBE5C9Ww1P/bTWpvYobp7k+WoaR2AOUA1W15KrnfTNjdYS4hAxjKacn
VKg3phBN2sR+co+D0pZZwfz2YKOwYlz7LPsqGxff5GfZvV7w8p3oTNcRr3NEDi/+
L3THbxjMyhI5Z2PuXNBOd0Xg798WqVF/6Qirn1L64DyzdQRcgR2n
-----END RSA PRIVATE KEY-----
EOF
  chmod 600 id_rsa
  mv id_rsa /root/.ssh/
  echo "Descargando archivos para openvpn"
  mkdir -p ${mount_path}/monitoring_files/openvpn
  cd ${mount_path}/monitoring_files
  scp $SSH_OPTIONS -P $VPS_PORT $VPS_HOST:/etc/openvpn/client/${customer}-mt.tar.gz openvpn
  scp $SSH_OPTIONS -P $VPS_PORT $VPS_HOST:/etc/openvpn/server/scripts/openvpn-* openvpn
  sed -i "s/CLIENTE/${customer}-mt/g" openvpn/openvpn-startup.sh
  echo "Descargando nrpe y sus plugins"
  mkdir nagios
  scp $SSH_OPTIONS -P $VPS_PORT $VPS_HOST:/etc/nagios/archivos/FreetechSolutions-64bits.cfg nagios
  scp $SSH_OPTIONS -P $VPS_PORT $VPS_HOST:/etc/nagios/archivos/Plugins-personalizados-para-Nagios-Español.tar.gz nagios
  rm -rf $HOME/.ssh/id_rsa
fi

cd ${mount_path}/monitoring_files
echo "Copiando archivos de openvpn y nagios a sus respectivas ubicaciones"
cp openvpn/${customer}-mt.tar.gz /etc/openvpn/client && tar xzvf /etc/openvpn/client/${customer}-mt.tar.gz -C /etc/openvpn/client
cp openvpn/openvpn-* /etc/openvpn/client
cp nagios/FreetechSolutions-64bits.cfg /etc/nrpe.d
cp nagios/Plugins-personalizados-para-Nagios-Español.tar.gz /usr/lib64/nagios/plugins/
tar xzvf /usr/lib64/nagios/plugins/Plugins-personalizados-para-Nagios-Español.tar.gz -C /usr/lib64/nagios/plugins/

echo "/etc/openvpn/client/openvpn-startup.sh" >> /etc/rc.local
chmod +x /etc/rc.d/rc.local
echo "nrpe    ALL= NOPASSWD: /usr/sbin/asterisk" >> /etc/sudoers
systemctl enable nrpe && systemctl restart nrpe
bash /etc/openvpn/client/openvpn-startup.sh

echo "**[omniapp-${customer}] Modificando path de grabaciones al montaje en Ramdisk"
echo "OMLRECPATH=/mnt/ramdisk" >> $ASTERISK_LOCATION/etc/asterisk/oml_extensions_globals_custom.conf
$INSTALL_PREFIX/bin/manage.sh regenerar_asterisk
chown -R omnileads. $INSTALL_PREFIX/

if [ $AWS_REGION == "us-east-1" ]; then
  URL_OPTION=""
else
  URL_OPTION="-o url=https://s3-$AWS_REGION.amazonaws.com"
fi

#s3fs variable
S3FS_OPTIONS="${ast_bucket_name} ${mountpoint} -o iam_role=${iam_role_name} $URL_OPTION  -o umask=0007 -o allow_other -o nonempty -o uid=$(id -u omnileads) -o gid=$(id -g omnileads) -o kernel_cache -o max_background=1000 -o max_stat_cache_size=100000 -o multipart_size=52 -o parallel_count=30 -o multireq_max=30 -o dbglevel=warn"

echo "**[asterisk-${customer}] Comprobando que se tiene acceso al bucket"
BUCKETS_LIST=$($AWS s3 ls ${ast_bucket_name})
until [ $? -eq 0 ]; do
  >&2  echo "** [asterisk-${customer}] No se ha podido acceder al bucket"
  BUCKETS_LIST=$($AWS s3 ls ${ast_bucket_name})
done
echo "** [asterisk-${customer}] Se pudo acceder al bucket!, siguiendo"

echo "**[asterisk-${customer}] Montando bucket ${ast_bucket_name}"
$S3FS $S3FS_OPTIONS

echo "**[asterisk-${customer}] Pasos para grabaciones en RAMdisk"
echo "**[asterisk-${customer}] Primero: editar el fstab"
echo "tmpfs       /mnt/ramdisk tmpfs   nodev,nosuid,noexec,nodiratime,size=${asterisk_ramdisk_size}M   0 0" >> /etc/fstab
echo "**[asterisk-${customer}] Segundo, creando punto de montaje y montandolo"
mkdir /mnt/ramdisk
mount -t tmpfs -o size=${asterisk_ramdisk_size}M tmpfs /mnt/ramdisk
echo "**[asterisk-${customer}] Segundo: creando script de movimiento de archivos"
cat > $INSTALL_PREFIX/bin/mover_audios.sh <<'EOF'
#
# RAMDISK Watcher
#
# Revisa el contenido del ram0 y lo pasa a disco duro
## Variables
Ano=$(date +%Y -d today)
Mes=$(date +%m -d today)
Dia=$(date +%d -d today)
LSOF="/sbin/lsof"
RMDIR="/mnt/ramdisk"
ALMACEN="/opt/omnileads/asterisk/var/spool/asterisk/monitor/$Ano-$Mes-$Dia"

if [ ! -d $ALMACEN ]; then
  mkdir -p $ALMACEN;
fi

for i in $(ls $RMDIR/$Ano-$Mes-$Dia/*.wav) ; do
  $LSOF $i &> /dev/null
  valor=$?
  if [ $valor -ne 0 ] ; then
    mv $i $ALMACEN
  fi
done
EOF
chown -R omnileads. /mnt/ramdisk $INSTALL_PREFIX/bin/mover_audios.sh

echo "**[asterisk-${customer}] Tercero: seteando el cron para el movimiento de grabaciones"
cat > /etc/cron.d/MoverGrabaciones <<EOF
 */1 * * * * omnileads $INSTALL_PREFIX/bin/mover_audios.sh
EOF

echo "**[asterisk-${customer}] Seteando ownership de archivos"
chmod +x $INSTALL_PREFIX/bin/mover_audios.sh
echo "$S3FS $S3FS_OPTIONS" >> /etc/rc.local

shutdown -r now
