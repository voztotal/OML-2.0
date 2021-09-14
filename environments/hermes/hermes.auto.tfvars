# Customer variables
asterisk_ramdisk_size   = "200"
customer                = "hermes"
environment             = "prod" //aqui puede ir dev o prod, dependiendo de que tipo es el entorno
customer_ec2_size       = "t2.micro"
ami_user                = "omnileadsami"
ami_password            = "5_MeO_DMT"
pg_database             = "hermes_oml"
pg_username             = "hermes_pg"
pg_password             = "admin123"
django_pass             = "FTS098098ZZZ"
ebs_volume_size         = 100
ECCTL                   = "28800"
omnileads_release       = "master"
pg_rds_size             = "db.t3.micro"
customer_root_disk_type = "standard"
customer_root_disk_size = 80
SCA                     = "3600"
shared_env              = "sharedus"
schedule                = "Agenda"
TZ                      = "America/Argentina/Cordoba"

# Wombat Dialer variables used if DIALER=yes if DIALER=no these variables doesn't care
dialer_ec2_size       = "t2.micro"
dialer_user           = "demoadmin"
dialer_password       = "demo"
dialer_root_disk_size = 20
mysql_database        = "wombat"
mysql_username        = "root" # no cambiar este username
mysql_password        = "admin123"
mysql_rds_size        = "db.t3.micro"
wombat_version        = "20.02.1-271"

## GENERAL VARS ## GENERAL VARS ## GENERAL VARS
## GENERAL VARS ## GENERAL VARS ## GENERAL VARS
cloud_provider = "aws"

app = "omlapp"

shared_bucket_name = "tfstate-shared"
tenant_bucket_callrec = "customer-name"
tenant_bucket_tfstate = "customer-name"

bucket_name = "tenantbucket"
bucket_acl = "private"
callrec_storage = "s3-aws"

nfs_host = "NULL"

## SIZING VARS ## SIZING VARS ## SIZING VARS
## SIZING VARS ## SIZING VARS ## SIZING VARS

instance_nic = "eth0"
# OMLapp component ec2 size
ec2_oml_size = "t2.medium"
# Asterisk component ec2 size
ec2_asterisk_size = "t2.micro"
# RTPengine componenet ec2 size
ec2_rtp_size = "t2.micro"
# REDIS component ec2 size
ec2_redis_size = "t2.micro"
# Wombat dialer component ec2 size
ec2_dialer_size = "t2.micro"
# Kamailio component ec2 size
ec2_kamailio_size = "t2.micro"
# Websocket component ec2 size
ec2_websocket_size = "t2.micro"
# PGSQL component digitalocean-cluster size
pgsql_size = "t2.micro"

## COMPONENETS NAME VARS ## COMPONENETS NAME VARS ## COMPONENETS NAME VARS
## COMPONENETS NAME VARS ## COMPONENETS NAME VARS ## COMPONENETS NAME VARS

# Don't change this variables !!!!
# Don't change this variables !!!!
# Don't change this variables !!!!
name = "customer-name"
oml_tenant_name = "customer-name"
name_rtpengine = "customer-name-rtp"
name_pgsql = "customer-name-pgsql"
name_redis = "customer-name-redis"
name_mariadb = "customer-name-mariadb"
name_wombat = "customer-name-wombat"
name_lb = "customer-name-lb"
name_kamailio = "customer-name-kamailio"
name_websocket = "customer-name-websocket"
name_asterisk = "customer-name-asterisk"
name_haproxy = "customer-name-haproxy"
name_omlapp = "customer-name"
omlapp_hostname = "customer-name.sefirot.cloud"
# OMLapp ec2 private NIC
omlapp_nginx_port = "443"

### OMniLeads App vars ### OMniLeads App vars ### OMniLeads App vars
### OMniLeads App vars ### OMniLeads App vars ### OMniLeads App vars

# ********************** Classic deploy
# Braches release to deploy
oml_app_branch="release-1.17.0"
oml_rtpengine_branch="rtp-27-dev-amazon-linux-compatibilidad"
oml_redis_branch="210714.01"
oml_kamailio_branch="kam-27-dev-amazon-linux-compatibilidad"
oml_acd_branch="210802.01"
oml_ws_branch="ws-27-dev-amazon-linux-compatibilidad"
oml_nginx_branch="210802.01"
oml_pgsql_branch="210714.01"

# ********************** Docker deploy
oml_app_img="latest"
oml_rtpengine_img="latest"
oml_redis_img="1.0.3"
oml_kamailio_img="latest"
oml_acd_img="latest"
oml_ws_img="latest"
oml_nginx_img="develop"

# ********************* OMniLeads App variables
# Asterisk SIP Trunks allowed ips
sip_allowed_ip = ["190.19.150.8/32"]
# Time Zone to apply on Django
oml_tz = "America/Argentina/Cordoba"

# Session cookie age
sca = "3600"

reset_admin_pass = "true"
init_environment = "true"

# Wombat dialer Component vars
wombat_database = "wombat"
wombat_database_username = "wombat"
wombat_database_password = "admin123"
