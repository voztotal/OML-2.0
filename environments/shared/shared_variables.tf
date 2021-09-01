variable "astsbc_ami_user" {
  description = "The user for internal manager in asterisk SBC"
  type        = "string"
}

variable "astsbc_ami_password" {
  description = "The password for internal manager in asterisk SBC"
  type        = "string"
}

variable "astsbc_rtp_min_port" {
  description = "The min UDP port for RTP in astsbc"
  type        = number
}

variable "astsbc_rtp_max_port" {
  description = "The max UDP port for RTP in astsbc"
  type        = number
}

variable "astsbc_version" {
  description = "The asterisk version to install in SBC"
  type        = "string"
}

variable "aws_region" {
  description = "The aws region to deploy infra"
  type        = "string"
}
variable "customer" {
  description = "Name of the costCenter of shared infra, default=shared"
  type        = "string"
  default     = "shared"
}
variable "disk_size_astsbc" {
  description = "The disk size in GB of astSBC ec2 instance"
  type        = number
}
variable "disk_size_rtpengine" {
  description = "The disk size in GBof rtpengine ec2 instance"
  type        = number
}
variable "domain_name" {
  description = "The domain configured in AWS"
  type        = string
}
variable "environment" {
  description = "The environment type for this customer (prod or dev)"
  type        = "string"
  default     = "prod"
}
variable "ec2_size_astsbc" {
  description = "The size of astSBC ec2 instance, check the sizes available in AWS"
  type        = "string"
}
variable "ec2_size_rtpengine" {
  description = "The size of rtpengine ec2 instance, check the sizes available in AWS"
  type        = "string"
}

variable "owner" {
  description = "The owner of project"
  type        = "string"
}
variable "pstn_trunks" {
  description = "The IP of the PSTN gateways that connect with SBC"
  type        = "list"
}

variable "rtpengine_rtp_min_port" {
  description = "The min UDP port for RTP in rtpengine"
  type        = number
}

variable "rtpengine_rtp_max_port" {
  description = "The max UDP port for RTP in rtpengine"
  type        = number
}

variable "rtpengine_version" {
  description = "The rtpengine version to install"
  type        = "string"
}
