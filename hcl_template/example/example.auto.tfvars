## GENERAL VARS ## GENERAL VARS ## GENERAL VARS
cloud_provider = "aws"
callrec_storage = "s3-aws"
nfs_host = "NULL"
instance_nic = "eth0"

## SIZING VARS ## SIZING VARS ## SIZING VARS

# OMLapp component ec2 size
ec2_oml_size            = "t2.medium"
# Asterisk component ec2 size
ec2_asterisk_size       = "t2.micro"
# REDIS component ec2 size
ec2_redis_size          = "t2.micro"
# Wombat dialer component ec2 size
ec2_dialer_size         = "t2.micro"
# Kamailio component ec2 size
ec2_kamailio_size       = "t2.micro"
# PGSQL component digitalocean-cluster size
pg_rds_size             = "db.t3.micro"

# Braches release to deploy
oml_app_branch          ="release-1.18.1"
oml_redis_branch        ="210714.01"
oml_kamailio_branch     ="kam-27-dev-amazon-linux-compatibilidad"
oml_acd_branch          ="210802.01"

# Customer variables
customer                = "example"
environment             = "prod" //aqui puede ir dev o prod, dependiendo de que tipo es el entorno
ami_user                = "omnileadsami"
ami_password            = "5_MeO_DMT"
pg_database             = "example_oml"
pg_username             = "example_pg"
pg_password             = "admin123"
ebs_volume_size         = 10
ECCTL                   = "28800"
customer_root_disk_type = "standard"
customer_root_disk_size = 20
SCA                     = "3600"
shared_env              = "sharedus"
schedule                = "Agenda"
TZ                      = "America/Argentina/Cordoba"

# Wombat Dialer variables used if DIALER=yes if DIALER=no these variables doesn't care
dialer_user             = "demoadmin"
dialer_password         = "demo"
dialer_root_disk_size   = 20
mysql_database          = "wombat"
mysql_username          = "root" # no cambiar este username
mysql_password          = "admin123"
mysql_rds_size          = "db.t3.micro"
wombat_version          = "20.02.1-271"
