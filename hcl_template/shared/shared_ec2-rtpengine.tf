resource "aws_iam_role_policy" "rtpengine_ec2_ssm_management" {
  name   = "rtpengineSsmManagement"
  role   = module.rtpengine_ec2.iam_role_id
  policy = templatefile("${path.module}/templates/ec2_ssm_policy.tpl", {})
}

resource "aws_iam_role_policy" "rtpengine_eip_allocation" {
  name   = "RtpengineEipAllocationhManagement"
  role   = module.rtpengine_ec2.iam_role_id
  policy = templatefile("${path.module}/templates/ec2_eip_allocation.tpl", {})
}

module "rtpengine_ec2" {

  additional_user_data = templatefile("${path.module}/templates/rtpengine_install.tpl", {
    aws_region        = var.aws_region
    eip_tag_name      = "${module.tags.tags.environment}-${var.customer}-rtpengineEIP"
    rtp_min_port      = var.rtpengine_rtp_min_port
    rtp_max_port      = var.rtpengine_rtp_max_port
    rtpengine_version = var.rtpengine_version
  })
  source                                      = "./modules/ec2-no-elb"
  vpc_id                                      = module.networking.vpc_id
  launch_config_image_id                      = data.aws_ami.amazon-linux-2.id
  launch_config_instance_type                 = var.ec2_size_rtpengine
  launch_config_key_name                      = aws_key_pair.ec2.key_name
  launch_config_associate_public_ip_address   = true
  launch_config_enable_monitoring             = true
  launch_config_root_block_device_volume_size = var.disk_size_rtpengine
  launch_config_root_block_device_volume_type = "gp2"
  asg_min_size                                = 1
  asg_max_size                                = 1
  asg_desired_capacity                        = 1
  asg_ec2_subnet_ids                          = module.networking.public_subnet_ids
  security_group_id                           = aws_security_group.rtpengine_ec2_sg.id
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-rtpengine-EC2"),
    map("role", "${module.tags.tags.environment}-${var.customer}-rtpengine-EC2")
  )
  asg_tag_names = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-rtpengine-EC2"),
    map("role", "${module.tags.tags.environment}-${var.customer}-rtpengine-EC2")
  )
}
