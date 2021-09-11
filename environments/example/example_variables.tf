variable "ami_user" {
  description = "The user for AMI asterisk"
  type        = "string"
}
variable "ami_password" {
  description = "The user for AMI asterisk"
  type        = "string"
}

variable "asterisk_ramdisk_size" {
  description = "The size of RAMDISK partition in asterisk customer EC2"
  type        = number
}
variable "aws_region" {
  description = "The AWS region to deploy the customer infra"
  type        = "string"
}
variable "customer" {
  description = "The customer to install"
  type        = "string"
}
variable "environment" {
  description = "The environment type for this customer (prod or dev)"
  type        = "string"
}
variable "customer_ec2_size" {
  description = "The size of rtpengine ec2 instance, check the sizes available in AWS"
  type        = "string"
}
variable "customer_root_disk_size" {
  description = "The disk size of root partition in customer EC2"
  type        = number
}
variable "customer_root_disk_type" {
  description = "The disk type of root partition in customer EC2 (can be standard or gp2)"
  type        = "string"
}
variable "gitlab_user" {
  description = "The gitlab user to clone repository with OMniLeads code"
  type        = "string"
}
variable "gitlab_password" {
  description = "The gitlab password to clone repository with OMniLeads code"
  type        = "string"
}
variable "mysql_database" {
  description = "The name of MYSQL database per client"
  type        = "string"
}
variable "mysql_username" {
  description = "The name of MYSQL user per client"
  type        = "string"
}
variable "mysql_password" {
  description = "The MYSQL password per client"
  type        = "string"
}
variable "mysql_rds_size" {
  description = "The size of RDS instances, check the sizes available in AWS"
  type        = "string"
}
variable "pg_database" {
  description = "The name of PG database per client"
  type        = "string"
}
variable "pg_username" {
  description = "The name of PG user per client"
  type        = "string"
}
variable "pg_password" {
  description = "The PG password per client"
  type        = "string"
}
variable "django_pass" {
  description = "The password of OMniLeads web admin"
  type        = "string"
}
variable "dialer_ec2_size" {
  description = "The size of dialer ec2 instance, check the sizes available in AWS"
  type        = "string"
}
variable "dialer_root_disk_size" {
  description = "The disk size of root partition in dialer EC2"
  type        = number
}
variable "dialer_user" {
  description = "The username of Wombat Dialer web admin"
  type        = "string"
}
variable "dialer_password" {
  description = "The password of Wombat Dialer web admin"
  type        = "string"
}
variable "domain_name" {
  description = "The domain configured in AWS"
  type        = "string"
}
variable "ebs_volume_size" {
  description = "The disk size of EBS volume in customer EC2"
  type        = number
}
variable "ECCTL" {
  description = "The number of seconds that ephimeral SIP credentials will last"
  type        = "string"
}
variable "omnileads_release" {
  description = "The OML release for this customer"
  type        = "string"
}
variable "omnileads_repository" {
  description = "The OML repository to install for this customer"
  type        = "string"
}
variable "owner" {
  description = "The owner of project"
  type        = "string"
}
variable "pg_rds_size" {
  description = "The size of RDS instances, check the sizes available in AWS"
  type        = "string"
}
variable "SCA" {
  description = "The number of seconds that django session will last"
  type        = "string"
}
variable "shared_env" {
  description = "The name of shared env that is going to be for this customer"
  type        = "string"
}
variable "schedule" {
  description = "The string name of the schedule disposition"
  type        = "string"
}
variable "TZ" {
  description = "The time zone for OML and WD instances"
  type        = "string"
}
variable "wombat_version" {
  description = "The wombat dialer version to install"
  type        = "string"
}
variable "aws_default_region" {
  type        = "string"
}

variable "name" {}
variable "oml_tenant_name" {}
variable "bucket_name" {}
variable "bucket_acl" {}

variable "shared_bucket_name" {}
variable "tenant_bucket_callrec" {}

variable "tenant_bucket_tfstate" {}

variable "cloud_provider" {}
variable "instance_nic" {}
variable "callrec_storage" {}

variable "nfs_host" {}

variable "init_environment" {}
variable "reset_admin_pass" {}

variable "name_rtpengine" {}
variable "name_pgsql" {}
variable "name_redis" {}
variable "name_mariadb" {}
variable "name_wombat" {}
variable "name_omlapp" {}
variable "name_kamailio" {}
variable "name_asterisk" {}
variable "name_websocket" {}
variable "name_lb" {}
variable "name_haproxy" {}

variable "oml_app_branch" {}
variable "oml_acd_branch" {}
variable "oml_redis_branch" {}
variable "oml_rtpengine_branch" {}
variable "oml_kamailio_branch" {}
variable "oml_ws_branch" {}
variable "oml_nginx_branch" {}
variable "oml_pgsql_branch" {}

variable "oml_app_img" {}
variable "oml_acd_img" {}
variable "oml_redis_img" {}
variable "oml_rtpengine_img" {}
variable "oml_kamailio_img" {}
variable "oml_ws_img" {}
variable "oml_nginx_img" {}

variable "ec2_oml_size" {}
variable "ec2_asterisk_size" {}
variable "ec2_rtp_size" {}
variable "ec2_dialer_size" {}
variable "ec2_kamailio_size" {}
variable "ec2_redis_size" {}
variable "ec2_websocket_size" {}
#variable "ec2_postgresql_size" {}
variable "pgsql_size" {}
#variable "ec2_haproxy_size" {}
# App # App # App

variable "sip_allowed_ip" {
  type    = list(string)
}

# OMniLeads deploy vars

variable "omlapp_nginx_port" {}
variable "oml_tz" {}
variable "omlapp_hostname" {}
variable "sca" {}
variable "ecctl" {
  default = "28800"
}
variable "extern_ip" {
  default = "none"
}

variable "kamailio_pkg_size" {
  default = "8"
}

variable "kamailio_shm_size" {
  default = "64"
}

# Wombat dialer
variable "wombat_database" {}
variable "wombat_database_username" {}
variable "wombat_database_password" {}
