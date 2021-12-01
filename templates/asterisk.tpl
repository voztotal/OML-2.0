#!/bin/bash

########################## README ############ README ############# README #######################
########################## README ############ README ############# README #########################
# El script first_boot_installer tiene como finalidad desplegar el componente sobre una instancia
# de linux exclusiva. Las variables que utiliza son "variables de entorno" de la instancia que está
# por lanzar el script como acto seguido al primer boot del sistema operativo.
# Dichas variables podrán ser provisionadas por un archivo .env (ej: Vagrant) o bien utilizando este
# script como plantilla de terraform.
#
# En el caso de necesitar ejecutar este script manualmente sobre el user_data de una instancia cloud
# o bien sobre una instancia onpremise a través de una conexión ssh, entonces se deberá copiar
# esta plantilla hacia un archivo ignorado por git: first_boot_installer.sh para luego sobre
# dicha copia descomentar las líneas que comienzan con la cadena "export" para posteriormente
# introducir el valor deseado a cada variable.
########################## README ############ README ############# README #########################
########################## README ############ README ############# README #########################

# *********************************** SET ENV VARS **************************************************
# The infrastructure environment:
# onpremise | digitalocean | linode | vultr
#export oml_infras_stage=

# Component gitlab branch
#export oml_acd_release=

# OMniLeads tenant NAME
#export oml_tenant_name=

# OMLApp netaddr
#export oml_app_host=
# REDIS netaddr
#export oml_redis_host=
# POSTGRESQL netaddr and port
#export oml_pgsql_host=
#export oml_pgsql_port=
# POSTGRESQL user, pass & DB params
#export oml_pgsql_db=
#export oml_pgsql_user=
#export oml_pgsql_password=
# IF PGSQL run on cloud cluster set this to true
#export oml_pgsql_cloud=NULL
# AMI conection from omlapp
#export oml_ami_user=
#export oml_ami_password=
# call recordings store params: NULL | s3 | nfs
#export oml_callrec_device=

# NFS addr when you select NFS like store for callrec
#export nfs_host=

# S3 params when you select S3 like store for callrec
#export s3_access_key=
#export s3_secret_key=
#export s3url=
#export s3_bucket_name=
# *********************************** SET ENV VARS **************************************************

SSM_AGENT_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"
S3FS="/bin/s3fs"

SRC=/usr/src
COMPONENT_REPO=https://gitlab.com/omnileads/omlacd.git
COMPONENT_REPO_DIR=omlacd

CALLREC_DIR_TMP=/opt/omnileads/asterisk/var/spool/asterisk/monitor
CALLREC_DIR_DST=/opt/callrec

echo "************************ disable SElinux *************************"
echo "************************ disable SElinux *************************"
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0
systemctl disable firewalld > /dev/null 2>&1
systemctl stop firewalld > /dev/null 2>&1

echo "************************ yum install *************************"
echo "************************ yum install *************************"

case ${oml_infras_stage} in
   aws)
     yum remove -y python3 python3-pip
     yum install -y $SSM_AGENT_URL 
     yum install -y patch libedit-devel libuuid-devel git
     amazon-linux-extras install -y epel
     amazon-linux-extras install python3 -y
     systemctl start amazon-ssm-agent
     ;;
   *)
     #yum update -y
     yum -y install epel-release git python3 python3-pip libselinux-python3
     ;;
 esac

# echo "************************ install ansible *************************"
# echo "************************ install ansible *************************"
pip3 install pip --upgrade
pip3 install boto boto3 botocore 'ansible==2.9.9' selinux
export PATH="$HOME/.local/bin/:$PATH"

# if [[ "${oml_infras_stage}" == "aws" ]];then
# ln -s /root/.local/lib/python3.6/site-packages/selinux /usr/lib64/python3.6/site-packages/
# fi

# echo "************************ clone REPO *************************"
# echo "************************ clone REPO *************************"
# echo "************************ clone REPO *************************"
cd $SRC
git clone $COMPONENT_REPO
cd omlacd
git checkout ${oml_acd_release}
cd deploy

# echo "******************************************* config and install *****************************************"
# echo "******************************************* config and install *****************************************"
# echo "******************************************* config and install *****************************************"
sed -i "s/omnileads_hostname=omnileads/omnileads_hostname=${oml_app_host}/g" ./inventory
sed -i "s/redis_hostname=redis/redis_hostname=${oml_redis_host}/g" ./inventory
sed -i "s/postgres_hostname=postgres/postgres_hostname=${oml_pgsql_host}/g" ./inventory
sed -i "s/postgres_port=5432/postgres_port=${oml_pgsql_port}/g" ./inventory
sed -i "s/postgres_database=omnileads/postgres_database=${oml_pgsql_db}/g" ./inventory
sed -i "s/postgres_user=omnileads/postgres_user=${oml_pgsql_user}/g" ./inventory
sed -i "s/postgres_password=my_very_strong_pass/postgres_password=${oml_pgsql_password}/g" ./inventory
sed -i "s/ami_user=omnileads/ami_user=${oml_ami_user}/g" ./inventory
sed -i "s/ami_password=C12H17N2O4P_o98o98/ami_password=${oml_ami_password}/g" ./inventory


if [[ "${oml_backup_filename}" != "NULL" ]];then
sed -i "s%\#backup_file_name=%backup_file_name=${oml_backup_filename}%g" ./inventory
fi
if [[ "${s3_access_key}" != "NULL" ]];then
sed -i "s%\#s3_access_key=%s3_access_key=${s3_access_key}%g" ./inventory
fi
if [[ "${s3_secret_key}" != "NULL" ]];then
sed -i "s%\#s3_secret_key=%s3_secret_key=${s3_secret_key}%g" ./inventory
fi
if [[ "${ast_bucket_name}" != "NULL" ]];then
sed -i "s%\#backup_bucket_name=%backup_bucket_name=${ast_bucket_name}%g" ./inventory
fi
if [[ "${s3url}" != "NULL" ]];then
sed -i "s%\#s3url=%s3url=${s3url}%g" ./inventory
fi
if [[ "${oml_auto_restore}" != "NULL" ]];then
sed -i "s/auto_restore=false/auto_restore=${oml_auto_restore}/g" ./inventory
fi

ansible-playbook asterisk.yml -i inventory --extra-vars "asterisk_version=$(cat ../.package_version)"

echo "************************ check if set SSLmode for PGSQL *************************"
echo "************************ check if set SSLmode for PGSQL *************************"

if [[ "${oml_pgsql_cloud}"  == "true" ]]; then
  echo "digitalocean requiere SSL to connect PGSQL"
  echo "SSLMode       = require" >> /etc/odbc.ini
fi

echo "************************ block_device mount *************************"
echo "************************ block_device mount *************************"

case ${oml_callrec_device} in
  s3-do)
    echo "s3 callrec device \n"
    yum install -y s3fs-fuse lsof
    echo "${s3_access_key}:${s3_secret_key} " > ~/.passwd-s3fs
    chmod 600 ~/.passwd-s3fs
       if [ ! -d $CALLREC_DIR_DST ]; then
      mkdir -p $CALLREC_DIR_DST
      chown -R omnileads. $CALLREC_DIR_DST
    fi
    echo "${ast_bucket_name} $CALLREC_DIR_DST fuse.s3fs _netdev,allow_other,use_path_request_style,url=${s3url} 0 0" >> /etc/fstab
    mount -a
    ;;
  s3-aws)
    echo "s3 callrec device \n"
    yum install -y s3fs-fuse lsof
    echo "${s3_access_key}:${s3_secret_key} " > ~/.passwd-s3fs
    chmod 600 ~/.passwd-s3fs
    if [ ! -d $CALLREC_DIR_DST ]; then
      mkdir -p $CALLREC_DIR_DST
      chown -R omnileads. $CALLREC_DIR_DST
    fi
    echo "${ast_bucket_name} $CALLREC_DIR_DST fuse.s3fs _netdev,allow_other 0 0" >> /etc/fstab
    mount -a
    ;;    
  nfs)
    echo "NFS callrec device \n"
    yum install -y nfs-utils nfs-utils-lib lsof
        if [ ! -d $CALLREC_DIR_DST ]; then
      mkdir -p $CALLREC_DIR_DST
      chown -R omnileads. $CALLREC_DIR_DST
    fi
    echo "${nfs_host}:$CALLREC_DIR_TMP $CALLREC_DIR_DST nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" >> /etc/fstab
    mount -a
    ;;
  *)
    echo "[ERROR] you must to define some net FS in order to put there callrec files"
    echo "[ERROR] you must to define some net FS in order to put there callrec files"
    echo "[ERROR] you must to define some net FS in order to put there callrec files"
    echo "[ERROR] you must to define some net FS in order to put there callrec files"
    echo "[ERROR] you must to define some net FS in order to put there callrec files"
    exit 0
    ;;
esac

echo "**************************** write callrec files move script ******************************"
echo "**************************** write callrec files move script ******************************"
cat > /opt/omnileads/mover_audios.sh <<EOF
#!/bin/bash

# RAMDISK Watcher
# Revisa el contenido del ram0 y lo pasa a disco duro
# Inicialización de variables

Ano=\$(date +%Y -d today)
Mes=\$(date +%m -d today)
Dia=\$(date +%d -d today)
Lsof="/sbin/lsof"
DirectorioFinal=$CALLREC_DIR_DST/\$Ano-\$Mes-\$Dia

if [ ! -d \$DirectorioFinal ];then
  mkdir -p \$DirectorioFinal
fi

for Grabacion in \$(ls $CALLREC_DIR_TMP/\$Ano-\$Mes-\$Dia/*.wav);do
  \$Lsof \$Grabacion &> /dev/null
  Resultado=\$?
  if [ \$Resultado -ne 0 ];then
    mv \$Grabacion \$DirectorioFinal
  fi
done
EOF

chown -R omnileads.omnileads /opt/omnileads/mover_audios.sh
chmod +x /opt/omnileads/mover_audios.sh

echo "****************************** add cron-line to trigger the call-recording move script **************************"
cat > /etc/cron.d/MoverGrabaciones <<EOF
*/1 * * * * omnileads /opt/omnileads/mover_audios.sh
EOF

if [[ "${oml_auto_restore}" != "NULL" ]];then
echo "50 23 * * * /opt/omnileads/omlutilities/backup-restore.sh --backup --asterisk --target=/opt/callrec" >> /var/spool/cron/omnileads
fi

echo "******************** Restart asterisk ***************************"
echo "******************** Restart asterisk ***************************"
chown -R omnileads. /opt/omnileads/asterisk
chown -R omnileads. $CALLREC_DIR_DST
systemctl enable asterisk
systemctl start asterisk

echo "********************************** sngrep SIP sniffer install *********************************"
echo "********************************** sngrep SIP sniffer install *********************************"
yum install ncurses-devel make libpcap-devel pcre-devel \
openssl-devel git gcc autoconf automake -y
cd $SRC && git clone https://github.com/irontec/sngrep
cd sngrep && ./bootstrap.sh && ./configure && make && make install
ln -s /usr/local/bin/sngrep /usr/bin/sngrep
