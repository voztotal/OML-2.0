## GENERAL VARS ## GENERAL VARS ## GENERAL VARS
cloud_provider = "aws"
callrec_storage = "s3-aws"
nfs_host = "NULL"
instance_nic = "eth0"

## SIZING VARS ## SIZING VARS ## SIZING VARS

# OMLapp component ec2 size
ec2_oml_size            = "t2.medium"
customer_root_disk_type = "standard"
customer_root_disk_size = 20
ebs_volume_size         = 10
# Asterisk component ec2 size
ec2_asterisk_size       = "t2.micro"
asterisk_root_disk_size = 50
# REDIS component ec2 size
ec2_redis_size          = "t2.micro"
# Wombat dialer component ec2 size
ec2_dialer_size         = "t2.micro"
dialer_root_disk_size   = 20
# Kamailio component ec2 size
ec2_kamailio_size       = "t2.micro"
kamailio_root_disk_size = 25
# Websockets component ec2 size
ec2_websockets_size       = "t2.micro"
websockets_root_disk_size = 25
# RDS PGSQL cluster size
pg_rds_size             = "db.t3.micro"
# RDS MySQL dialer backend SQL
mysql_rds_size          = "db.t3.micro"


# Braches release to deploy
oml_app_branch          ="release-1.24.2"
oml_redis_branch        ="220606.01"
oml_kamailio_branch     ="220614.01"
oml_acd_branch          ="220614.01"
oml_websockets_branch   ="220818.01"

# Customer variables
customer                = "example"
environment             = "prod" //aqui puede ir dev o prod, dependiendo de que tipo es el entorno
ami_user                = "omnileadsami"
ami_password            = "5_MeO_DMT"
pg_database             = "example_oml"
pg_username             = "example_pg"
pg_password             = "admin123"
ECCTL                   = "28800"
SCA                     = "3600"
shared_env              = "sharedus"
schedule                = "Agenda"
TZ                      = "America/Argentina/Cordoba"

# Wombat Dialer variables used if DIALER=yes if DIALER=no these variables doesn't care
dialer_user             = "demoadmin"
dialer_password         = "demo"
mysql_database          = "wombat"
mysql_username          = "root" # no cambiar este username
mysql_password          = "admin123"
wombat_version          = "20.02.1-271"

reset_admin_pass        = "true"

# Kamailio tweeks
kamailio_shm_size       = "256"
kamailio_pkg_size       = "32"
# Hight Load components tweeks
oml_high_load           = "NULL"

google_maps_api_key     ="NULL"
google_maps_center      ="NULL"
