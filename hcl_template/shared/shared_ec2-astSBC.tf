

resource "aws_iam_role_policy" "astsbc_ec2_ssm_management" {
  name   = "AstsbcSsmManagement"
  role   = module.astsbc_ec2.iam_role_id
  policy = templatefile("${path.module}/templates/ec2_ssm_policy.tpl", {})
}

resource "aws_iam_role_policy" "astsbc_ec2_s3_access_management" {
  name = "AstsbcS3FullAccessManagement"
  role = module.astsbc_ec2.iam_role_id
  policy = templatefile("${path.module}/templates/s3_full_access_policy.tpl", {
    astsbc_s3_bucket = aws_s3_bucket.astsbc_configuration.arn
  })
}

resource "aws_iam_role_policy" "astsbc_eip_allocation" {
  name   = "AstsbcEipAllocationhManagement"
  role   = module.astsbc_ec2.iam_role_id
  policy = templatefile("${path.module}/templates/ec2_eip_allocation.tpl", {})
}

module "astsbc_ec2" {

  additional_user_data = templatefile("${path.module}/templates/astsbc_install.tpl", {
    ami_user           = var.astsbc_ami_user
    ami_password       = var.astsbc_ami_password
    aws_region         = var.aws_region
    astsbc_version     = var.astsbc_version
    astsbc_bucket_name = split(".", aws_s3_bucket.astsbc_configuration.bucket_domain_name)[0]
    eip_tag_name       = "${module.tags.tags.environment}-${var.customer}-astsbcEIP"
    rtp_min_port       = var.astsbc_rtp_min_port
    rtp_max_port       = var.astsbc_rtp_max_port
    }
  )
  source                                      = "./modules/ec2-no-elb"
  vpc_id                                      = module.networking.vpc_id
  launch_config_image_id                      = data.aws_ami.amazon-linux-2.id
  launch_config_instance_type                 = var.ec2_size_astsbc
  launch_config_key_name                      = aws_key_pair.ec2.key_name
  launch_config_associate_public_ip_address   = true
  launch_config_enable_monitoring             = true
  launch_config_root_block_device_volume_size = var.disk_size_astsbc
  launch_config_root_block_device_volume_type = "gp2"
  asg_min_size                                = 1
  asg_max_size                                = 1
  asg_desired_capacity                        = 1
  asg_ec2_subnet_ids                          = module.networking.public_subnet_ids
  asg_target_group_arns                       = [module.astsbc_int_sip_nlb.default_target_group_arn]
  security_group_id                           = aws_security_group.astsbc_ec2_sg.id
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-astsbc-EC2"),
    map("role", "${module.tags.tags.environment}-${var.customer}-astsbc-EC2")
  )
  asg_tag_names = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-astsbc-EC2"),
    map("role", "${module.tags.tags.environment}-${var.customer}-astsbc-EC2")
  )
}

resource "aws_s3_bucket" "astsbc_configuration" {
  bucket = "${module.tags.tags.prefix}-${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-astsbc-configuration"
  acl    = "private"
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-astsbc-configuration"),
    map("role", "${module.tags.tags.environment}-${var.customer}-astsbc-configuration")
  )
}
