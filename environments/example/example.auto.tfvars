# Customer variables
asterisk_ramdisk_size   = "200"
customer                = "example"
environment             = "prod" //aqui puede ir dev o prod, dependiendo de que tipo es el entorno
customer_ec2_size       = "t2.micro"
ami_user                = "omnileadsami"
ami_password            = "5_MeO_DMT"
pg_database             = "example_oml"
pg_username             = "example_pg"
pg_password             = "admin123"
django_pass             = "FTS098098ZZZ"
ebs_volume_size         = 100
ECCTL                   = "28800"
omnileads_release       = "develop"
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
