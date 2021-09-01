data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_iam_role_policy" "ec2_ssm_management" {
  name   = "${var.customer}SsmManagement"
  role   = module.ec2.iam_role_id
  policy = templatefile("${path.module}/templates/ec2_ssm_policy.tpl", {})
}

resource "aws_iam_role_policy" "ec2_ebs_attach_management" {
  name   = "${var.customer}EbsAttachManagement"
  role   = module.ec2.iam_role_id
  policy = templatefile("${path.module}/templates/ec2_ebs_attach_policy.tpl", {})
}

resource "aws_iam_role_policy" "ec2_s3_access_management" {
  name = "${var.customer}S3FullAccessManagement"
  role = module.ec2.iam_role_id
  policy = templatefile("${path.module}/templates/s3_full_access_policy.tpl", {
    astsbc_s3_bucket = aws_s3_bucket.customer_data.arn
  })
}

module "ec2" {
  additional_user_data = templatefile("${path.module}/templates/aio.tpl", {
    ast_bucket_name        = split(".", aws_s3_bucket.customer_data.bucket_domain_name)[0]
    iam_role_name          = module.ec2.iam_role_name
    asterisk_ramdisk_size  = var.asterisk_ramdisk_size
    mountpoint             = "/opt/omnileads/asterisk/var/spool/asterisk/monitor"
    aws_region             = var.aws_region
    device_tag_name        = "${module.tags.tags.environment}-${var.customer}-opt-EBS"
    device_path            = "/dev/xvdcx"
    mount_path             = "/var/tmp/omnileads"
    ami_user               = var.ami_user
    ami_password           = var.ami_password
    customer               = var.customer
    gitlab_user            = var.gitlab_user
    gitlab_password        = var.gitlab_password
    mysql_password         = var.mysql_password
    pg_database         = var.pg_database
    pg_username         = var.pg_username
    pg_password         = var.pg_password
    dialer_user         = var.dialer_user
    dialer_password     = var.dialer_password
    django_pass         = var.django_pass
    omnileads_release   = var.omnileads_release
    omnileads_repository = var.omnileads_repository
    ECCTL               = var.ECCTL
    dialer_host       = local.dialer_host != null ? local.dialer_host : ""
    mysql_host        = local.mysql_host != null ? local.mysql_host : ""
    pg_host           = module.rds_postgres.address
    rtpengine_host    = data.terraform_remote_state.shared_state.outputs.rtpengine_fqdn
    SCA               = var.SCA
    schedule          = var.schedule
    vpc_subnet        = data.terraform_remote_state.shared_state.outputs.vpc_cidr_block
    TZ                = var.TZ
  })
  source                                      = "./modules/ec2-no-elb"
  vpc_id                                      = data.terraform_remote_state.shared_state.outputs.vpc_id
  launch_config_key_name                      = data.terraform_remote_state.shared_state.outputs.ec2_key
  launch_config_instance_type                 = var.customer_ec2_size
  launch_config_image_id                      = data.aws_ami.amazon-linux-2.id
  launch_config_root_block_device_volume_size = var.customer_root_disk_size
  launch_config_root_block_device_volume_type = var.customer_root_disk_type
  launch_config_associate_public_ip_address   = false
  launch_config_enable_monitoring             = true
  asg_min_size                                = 1
  asg_max_size                                = 1
  asg_desired_capacity                        = 1
  asg_ec2_subnet_ids                          = data.terraform_remote_state.shared_state.outputs.private_subnet_ids
  asg_target_group_arns                       = local.ec2_target_group_arns
  security_group_id                           = aws_security_group.tenants_ec2_sg.id
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-EC2"),
    map("role", "${module.tags.tags.environment}-${var.customer}-EC2")
  )
  asg_tag_names = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-EC2"),
    map("role", "${module.tags.tags.environment}-${var.customer}-EC2")
  )
}

resource "aws_s3_bucket" "customer_data" {
  bucket = "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data"
  acl    = "private"
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data"),
    map("role", "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data")
  )
}

module "aws_backup_oml" {
  source             = "./modules/tf-aws-backup"
  namespace          = var.customer
  stage              = module.tags.tags.environment
  name               = "backups"
  tags               = module.tags.tags
  backup_resources   = local.backup_resources
  schedule           = "cron(0 4 ? * * *)"
  #cold_storage_after = 15
  delete_after       = 15
}
