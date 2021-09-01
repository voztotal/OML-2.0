#!/bin/bash

systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

echo "Seteando timezone"
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/${TZ} /etc/localtime

yum update -y
amazon-linux-extras install epel
wget -P /etc/yum.repos.d http://yum.loway.ch/loway.repo
yum install wombat -y

echo "Ejecutando tareas postinstall para que wombat tenga acceso a mysql RDS"

cat > /usr/local/queuemetrics/tomcat/webapps/wombat/WEB-INF/tpf.properties <<EOF
#LICENZA_ARCHITETTURA=....
#START_TRANSACTION=qm_start
JDBC_DRIVER=org.mariadb.jdbc.Driver
JDBC_URL=jdbc:mariadb://${mysql_host}/${mysql_database}?user=${mysql_username}&password=${mysql_password}&autoReconnect=true
#SMTP_HOST=my.host
#SMTP_AUTH=true
#SMTP_USER=xxxx
#SMTP_PASSWORD=xxxxx
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_AUTH=yes
SMTP_USER=your-gmail-account@gmail.com
SMTP_PASSWORD=wombat
SMTP_USE_SSL=no
SMTP_FROM="WombatDialer" <your-gmail-account@gmail.com>
SMTP_DEBUG=yes

pwd.defaultLevel=1
pwd.minAllowedLevel=1
EOF

echo "Ejecutando tareas de monitoreo"
VPS_HOST="www.freetech.com.ar"
VPS_PORT="40404"
SSH_OPTIONS="-o stricthostkeychecking=no -o ConnectTimeout=10"

echo "Instalando openvpn y nagios"
yum install nrpe nagios-plugins-all bc openvpn -y
cd /etc/nagios
sed -i "s/allowed_hosts=127.0.0.1,::1/allowed_hosts=127.0.0.1,10.20.0.1/g" nrpe.cfg
sed -i "s/dont_blame_nrpe=0/dont_blame_nrpe=1/g" nrpe.cfg

if [ ! -d /root/monitoring_files ];then
  echo "Creando llave privada para entrar por ssh a VPS"
  mkdir /root/.ssh
  cd /root
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
  mkdir -p /root/monitoring_files/openvpn
  cd /root/monitoring_files
  scp $SSH_OPTIONS -P $VPS_PORT $VPS_HOST:/etc/openvpn/client/${customer}-dialer-mt.tar.gz openvpn
  scp $SSH_OPTIONS -P $VPS_PORT $VPS_HOST:/etc/openvpn/server/scripts/openvpn-* openvpn
  sed -i "s/CLIENTE/${customer}-dialer-mt/g" openvpn/openvpn-startup.sh
  echo "Descargando nrpe y sus plugins"
  mkdir nagios
  scp $SSH_OPTIONS -P $VPS_PORT $VPS_HOST:/etc/nagios/archivos/FreetechSolutions-64bits.cfg nagios
  scp $SSH_OPTIONS -P $VPS_PORT $VPS_HOST:/etc/nagios/archivos/Plugins-personalizados-para-Nagios-Español.tar.gz nagios
  rm -rf $HOME/.ssh/id_rsa
fi

cd /root/monitoring_files
echo "Copiando archivos de openvpn y nagios a sus respectivas ubicaciones"
cp openvpn/${customer}-dialer-mt.tar.gz /etc/openvpn/client && tar xzvf /etc/openvpn/client/${customer}-dialer-mt.tar.gz -C /etc/openvpn/client
cp openvpn/openvpn-* /etc/openvpn/client
cp nagios/FreetechSolutions-64bits.cfg /etc/nrpe.d
cp nagios/Plugins-personalizados-para-Nagios-Español.tar.gz /usr/lib64/nagios/plugins/
tar xzvf /usr/lib64/nagios/plugins/Plugins-personalizados-para-Nagios-Español.tar.gz -C /usr/lib64/nagios/plugins/

echo "/etc/openvpn/client/openvpn-startup.sh" >> /etc/rc.local
chmod +x /etc/rc.d/rc.local
systemctl enable nrpe && systemctl restart nrpe
shutdown -r now
