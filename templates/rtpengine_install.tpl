#!/bin/bash
# Enviroment variables
set -ex

#SSM_AGENT_URL="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm"
PRIVATE_IPV4=$(hostname -I)
RTPENGINE_PORT=22222
PORT_MIN=${rtp_min_port}
PORT_MAX=${rtp_max_port}

echo "***[rtpengine] Instalando amazon-ssm-agent"
amazon-linux-extras install epel
#yum install -y $SSM_AGENT_URL

#echo "***[rtpengine] Habilitando e iniciando ssm-agent"
#systemctl start amazon-ssm-agent
#systemctl enable amazon-ssm-agent

AWS="/usr/bin/aws"
EC2_METADATA="/usr/bin/ec2-metadata"
INSTANCE_ID=$($EC2_METADATA -i | awk '{print $2}')

echo "***[rtpengine] Obteniendo la EIP para rtpengine"
DISCOVERED_ELASTIC_IP=$($AWS ec2 describe-addresses  \
--region ${aws_region} \
--public-ips \
--filters Name=tag:Name,Values=${eip_tag_name} \
 |grep -w PublicIp |awk '{print $2}'|awk -F "\"" '{print $2}')

echo "***[rtpengine] Attachando la EIP a la instancia"
$AWS ec2 associate-address \
  --instance-id $INSTANCE_ID \
  --public-ip $DISCOVERED_ELASTIC_IP \
  --region ${aws_region}

sleep 10

PUBLIC_IPV4=$($EC2_METADATA --public-ipv4 |awk -F " " '{print $2}')

echo "***[rtpengine] Instalando rtpengine y su paqueteria necesaria"
yum install -y kernel-devel \
  libpcap \
  xmlrpc-c-client \
  json-glib \
  libevent \
  hiredis \
  https://fts-public-packages.s3.amazonaws.com/rtpengine-${rtpengine_version}-1.x86_64.rpm

#echo "***[rtpengine] Añadiendo el modulo de kernel"
#insmod /root/xt_RTPENGINE.ko

echo "***[rtpengine] Añadiendo el archivo de configuración /etc/rtpengine-config.conf"
cat > /etc/rtpengine-config.conf <<EOF
OPTIONS="-i external/$${PRIVATE_IPV4::-1}!$PUBLIC_IPV4 -o 60 -a 3600 -d 30 -s 120 -n $${PRIVATE_IPV4::-1}:$RTPENGINE_PORT -m $PORT_MIN -M $PORT_MAX --table=0 -L 7 --log-stderr"
EOF

# Fix Amazon Linux 2
cd /usr/lib64/
ln -s libip4tc.so.2 libip4tc.so.0
ln -s libip6tc.so.2 libip6tc.so.0

echo "***[rtpengine] Iniciando y habilitando rtpengine"
systemctl enable rtpengine
systemctl start rtpengine
