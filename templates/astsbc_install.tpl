#!/bin/bash

set -ex

#SSM_AGENT_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"
PROGNAME=$(basename $0)
ASTERISK_VERSION=${astsbc_version}
PREFIX="/opt/omnileads/asterisk"
AWS="/usr/bin/aws"
EC2_METADATA="/usr/bin/ec2-metadata"
INSTANCE_ID=$($EC2_METADATA -i | awk '{print $2}')
USUARIO="asterisk"

echo "***[astsbc] Instalando amazon-ssm-agent"
amazon-linux-extras install epel
#yum install -y $SSM_AGENT_URL

echo "***[astsbc] Iniciando y habilitando ssm-agent"
#systemctl start amazon-ssm-agent
#systemctl enable amazon-ssm-agent

echo "***[astsbc] Seteando las envars AMI_USER y AMI_PASSWORD"
echo -e "\n
export AMI_USER=${ami_user}\n
export AMI_PASSWORD=${ami_password}" >> /root/.bashrc

if test -z $${ASTERISK_VERSION}; then
  echo "$${PROGNAME}: ASTERISK_VERSION required" >&2
  exit 1
fi

echo "***[astsbc] Añadiendo usuario asterisk"
useradd --system $USUARIO
echo "Instalando kernel-devel, git, asterisk y librerias necesarias"
yum install -y kernel-devel \
  git \
  gsm \
  https://fts-public-packages.s3.amazonaws.com/asterisk-${astsbc_version}-1.x86_64.rpm \
  python3-pip \
  libxslt \
  ncurses-compat-libs \
  uriparser

echo "***[astsbc] Linkeando ubicación de asterisk a $PREFIX"
mkdir /opt/asterisk
ln -s $PREFIX/ /opt/asterisk

echo "***[astsbc] Obtengo la IP publica creada para astSBC"
DISCOVERED_ELASTIC_IP=$($AWS ec2 describe-addresses  \
--region ${aws_region} \
--public-ips \
--filters Name=tag:Name,Values=${eip_tag_name} \
  |grep -w PublicIp |awk '{print $2}'|awk -F "\"" '{print $2}')

echo "***[astsbc] Attaching the EIP to this instance"
$AWS ec2 associate-address \
  --instance-id $INSTANCE_ID \
  --public-ip $DISCOVERED_ELASTIC_IP \
  --region ${aws_region}

echo "***[astsbc] Añado repositorio de astsbc"
cd /root && git clone https://gitlab.com/psychodoom/sbc4oml.git
cd sbc4oml/conf
chmod +x sbc_agi.sh
cp *.conf $PREFIX/etc/asterisk
cp sbc_agi.sh $PREFIX/var/lib/asterisk/agi-bin
touch $PREFIX/var/log/asterisk/sbc.log

echo "***[astsbc] Detecto si no existen archivos que se escribe en scripts de deploy, si no existen los creo para que asterisk levante bien"
if [ ! -f $PREFIX/etc/asterisk/sbc_extensions_to_outside.conf ]; then touch $PREFIX/etc/asterisk/sbc_extensions_to_outside.conf; fi
if [ ! -d $PREFIX/etc/asterisk/sbc_pjsip_endpoints_outside.conf ]; then touch $PREFIX/etc/asterisk/sbc_pjsip_endpoints_outside.conf; fi
if [ ! -d $PREFIX/etc/asterisk/sbc_pjsip_endpoints_omls.conf ]; then touch  $PREFIX/etc/asterisk/sbc_pjsip_endpoints_omls.conf; fi

echo "***[astsbc] Descargo la configuracion del bucket"
if [ ! -d $PREFIX/etc ]; then mkdir -p $PREFIX/etc; fi
if [ ! -d $PREFIX/var/lib/asterisk/ ]; then mkdir -p $PREFIX/var/lib/asterisk/; fi
$AWS s3 sync s3://${astsbc_bucket_name} $PREFIX/etc/
$AWS s3 cp s3://${astsbc_bucket_name}/astdb.sqlite3 $PREFIX/var/lib/asterisk/astdb.sqlite3 || true

echo "***[astsbc] Installing pyst2 library"
pip3 install setuptools
pip3 install git+https://github.com/SrMoreno/pyst2@master#egg=pyst2

echo "***[astsbc] Modificando manager.conf con user y pass pasados en variables"
cat > $PREFIX/etc/asterisk/manager.conf <<EOF
[general]
enabled = yes
webenabled = yes
bindaddr=0.0.0.0
port = 5038

[${ami_user}]
secret = ${ami_password}
deny = 0.0.0.0/0.0.0.0
permit = 127.0.0.1/255.255.255.255
read = all
write = all
EOF

echo "***[astsbc] Modificando rtp.conf con puertos UDP pasados en variables"
cat > $PREFIX/etc/asterisk/rtp.conf <<EOF
[general]
rtpstart=${rtp_min_port}
rtpend=${rtp_max_port}
EOF

echo "***[astsbc] Seteando permisos de la carpeta $PREFIX"
chown -R $USUARIO:$USUARIO $PREFIX/ $PREFIX/../asterisk
chmod -R 750 $PREFIX

echo "***[astsbc] Linkeando binario de asterisk a /usr/sbin"
ln -s $PREFIX/sbin/asterisk /usr/sbin/

echo "**[astsbc] Instalando sngrep"
yum install ncurses-devel make libpcap-devel pcre-devel \
    openssl-devel git gcc autoconf automake -y
cd /root && git clone https://github.com/irontec/sngrep
cd sngrep && ./bootstrap.sh && ./configure && make && make install
ln -s /usr/local/bin/sngrep /usr/bin/sngrep

echo "***[astsbc] Modificando el script de systemd de asterisk"
sed -i "/EnvironmentFile/d" /etc/systemd/system/asterisk.service
sed -i "s/User=.*/User=$USUARIO/g" /etc/systemd/system/asterisk.service
sed -i "s/Environment=.*/Environment=User=$USUARIO/g" /etc/systemd/system/asterisk.service

echo "***[astsbc] Setting logrotate of asterisk log"
cat > /etc/logrotate.d/asterisk <<EOF
/opt/omnileads/asterisk/var/log/asterisk/full {
    daily
    rotate 5
    missingok
    notifempty
    compress
    sharedscripts
    postrotate
        /usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null
    endscript
}
EOF

sed -i "s/astsbc.fts-cloud.net/astsbc-${customer}.${domain_name}/g" $PREFIX/etc/asterisk/sbc_pjsip_transports.conf

echo "***[astsbc] Habilitando e iniciando asterisk"
systemctl enable asterisk
exec service asterisk start
