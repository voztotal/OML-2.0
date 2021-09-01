resource "aws_iam_role_policy" "dialer_ec2_ssm_management" {
  name   = "${var.customer}DialerSsmManagement"
  role   = module.dialer_ec2.iam_role_id
  policy = templatefile("${path.module}/templates/ec2_ssm_policy.tpl", {})
}

module "dialer_ec2" {
  additional_user_data = templatefile("${path.module}/templates/dialer_install.tpl", {
    customer       = var.customer
    wombat_version = var.wombat_version
    mysql_host     = local.mysql_host
    mysql_database = var.mysql_database
    mysql_username = var.mysql_username
    mysql_password = var.mysql_password
    TZ             = var.TZ

  })
  source                                      = "./modules/ec2-no-elb"
  vpc_id                                      = data.terraform_remote_state.shared_state.outputs.vpc_id
  launch_config_key_name                      = data.terraform_remote_state.shared_state.outputs.ec2_key
  launch_config_instance_type                 = var.dialer_ec2_size
  launch_config_image_id                      = data.aws_ami.amazon-linux-2.id
  launch_config_root_block_device_volume_size = var.dialer_root_disk_size
  launch_config_root_block_device_volume_type = "standard"
  launch_config_associate_public_ip_address   = false
  launch_config_enable_monitoring             = true
  asg_min_size                                = 1
  asg_max_size                                = 1
  asg_desired_capacity                        = 1
  asg_ec2_subnet_ids                          = data.terraform_remote_state.shared_state.outputs.private_subnet_ids
  asg_target_group_arns                       = [aws_lb_target_group.wdint_target_group.arn, aws_lb_target_group.wdext_target_group.arn]
  security_group_id                           = aws_security_group.tenants_ec2_sg.id
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-dialer-EC2"),
    map("role", "${module.tags.tags.environment}-${var.customer}-dialer-EC2")
  )
  asg_tag_names = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-dialer-EC2"),
    map("role", "${module.tags.tags.environment}-${var.customer}-dialer-EC2")
  )
}
