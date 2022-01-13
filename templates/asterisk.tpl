#!/bin/bash

SSM_AGENT_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"
S3FS="/bin/s3fs"

SRC=/usr/src
COMPONENT_REPO=https://gitlab.com/omnileads/omlacd.git
COMPONENT_REPO_DIR=omlacd

CALLREC_DIR_TMP=/opt/omnileads/asterisk/var/spool/asterisk/monitor

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
     yum install -y lame gsm
     systemctl start amazon-ssm-agent
     ;;
   *)
     #yum update -y
     yum -y install epel-release git python3 python3-pip libselinux-python3 lame gsm
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
sed -i "s%\TZ=set_your_timezone_here%TZ=${oml_tz}%g" ./inventory
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
if [[ "${s3_bucket_name}" != "NULL" ]];then
sed -i "s%\#s3_bucket_name=%s3_bucket_name=${s3_bucket_name}%g" ./inventory
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
    echo "${s3_bucket_name} $CALLREC_DIR_DST fuse.s3fs _netdev,allow_other,use_path_request_style,url=${s3url} 0 0" >> /etc/fstab
    mount -a
    ;;
  s3-aws)
    echo "AWS S3 \n"
    echo "55 23 * * * source /etc/profile.d/omnileads_envars.sh && aws s3 sync /opt/omnileads/backup s3://${s3_bucket_name}/omlacd-backup" >> /var/spool/cron/omnileads
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
    exit 0
    ;;
esac

echo "********************* Activate cron callrec mv & convert to mp3 and backup *****************"
echo "********************* Activate cron callrec mv & convert to mp3 and backup *****************"
mkdir /opt/omnileads/log && touch /opt/omnileads/log/conversor.log
chown omnileads.omnileads -R /opt/omnileads/log

echo "50 23 * * * source /etc/profile.d/omnileads_envars.sh && /opt/omnileads/utils/backup-restore.sh --backup --asterisk" >> /var/spool/cron/omnileads
echo "0 1 * * * source /etc/profile.d/omnileads_envars.sh && /opt/omnileads/utils/conversor.sh 2 0 >> /opt/omnileads/log/conversor.log" >> /var/spool/cron/omnileads
echo "*/1 * * * * source /etc/profile.d/omnileads_envars.sh && /opt/omnileads/utils/mover_audios.sh" >> /var/spool/cron/omnileads

touch /etc/cron.d/cleanTmp
echo "10 0 * * 6 root rm -rf /tmp/*" > /etc/cron.d/cleanTmp


echo "******************** Restart asterisk ***************************"
echo "******************** Restart asterisk ***************************"
chown -R omnileads. /opt/omnileads/
systemctl enable asterisk
systemctl restart asterisk

echo "********************************** sngrep SIP sniffer install *********************************"
echo "********************************** sngrep SIP sniffer install *********************************"
yum install -y ncurses-devel make libpcap-devel pcre-devel openssl-devel git gcc autoconf automake
cd $SRC && git clone https://github.com/irontec/sngrep
cd sngrep && ./bootstrap.sh && ./configure && make && make install
ln -s /usr/local/bin/sngrep /usr/bin/sngrep
