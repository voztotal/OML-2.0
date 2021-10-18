variable "ami_user" {
  description = "The user for AMI asterisk"
  type        = "string"
}
variable "ami_password" {
  description = "The user for AMI asterisk"
  type        = "string"
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
variable "customer_root_disk_size" {
  description = "The disk size of root partition in customer EC2"
  type        = number
}
variable "customer_root_disk_type" {
  description = "The disk type of root partition in customer EC2 (can be standard or gp2)"
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
variable "dialer_root_disk_size" {
  description = "The disk size of root partition in dialer EC2"
  type        = number
}
variable "oml_app_repo_url" {
  description = "URL for omlapp repository"
  type        = string
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

variable "cloud_provider" {}
variable "instance_nic" {}
variable "callrec_storage" {}

variable "nfs_host" {}

variable "init_environment" {}
variable "reset_admin_pass" {}


variable "oml_app_branch" {}
variable "oml_acd_branch" {}
variable "oml_redis_branch" {}
variable "oml_kamailio_branch" {}

variable "ec2_oml_size" {}
variable "ec2_asterisk_size" {}
variable "ec2_dialer_size" {}
variable "ec2_kamailio_size" {}
variable "ec2_redis_size" {}
# App # App # App

variable "kamailio_pkg_size" {
  default = "8"
}

variable "kamailio_shm_size" {
  default = "64"
}
variable "pstn_trunks" {
  description = "The IP of the PSTN gateways that connect with SBC"
  type        = "list"
}
variable  "s3_access_key"{}
variable  "s3_secret_key" {}