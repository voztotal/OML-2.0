resource "aws_s3_bucket" "customer_data" {
  bucket = "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data"
  acl    = "private"
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data"),
    map("role", "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data")
  )
}

module "ec2" {
  additional_user_data = templatefile("${path.module}/templates/omlapp.tpl", {
    bucket_name               = split(".", aws_s3_bucket.customer_data.bucket_domain_name)[0]
    bucket_access_key         = var.s3_access_key
    bucket_secret_key         = var.s3_secret_key
    oml_deploytool_branch     = var.omldeploytool_branch
    obs_host                  = var.obs_host
    iam_role_name             = module.ec2.iam_role_name
    aws_region                = var.aws_region
    oml_app_repo_url          = var.oml_app_repo_url
    oml_ami_user              = var.ami_user
    oml_ami_password          = var.ami_password
    oml_pgsql_host            = module.rds_postgres.address
    oml_pgsql_port            = 5432
    oml_pgsql_db              = var.pg_database
    oml_pgsql_user            = var.pg_username
    oml_pgsql_password        = var.pg_password
    oml_pgsql_cloud           = "true"
    oml_dialer_host           = local.dialer_host != null ? local.dialer_host : ""
    api_dialer_user           = var.dialer_user
    api_dialer_password       = var.dialer_password
    oml_app_tag               = var.oml_app_branch
    oml_websockets_release    = var.oml_websockets_branch
    oml_kamailio_release      = var.oml_kamailio_branch
    oml_nginx_release         = var.oml_nginx_branch
    oml_app_ecctl             = var.ECCTL
    oml_rtpengine_host        = data.terraform_remote_state.shared_state.outputs.rtpengine_fqdn
    oml_obs_host              = var.obs_host
    oml_app_sca               = var.SCA
    vpc_subnet                = data.terraform_remote_state.shared_state.outputs.vpc_cidr_block
    oml_tz                    = var.TZ
    oml_infras_stage          = var.cloud_provider
    oml_tenant_name           = var.customer
    oml_callrec_device        = var.callrec_storage
    oml_extern_ip             = "auto"
    oml_app_login_fail_limit  = 10
    oml_app_init_env          = "NULL"
    oml_app_install_sngrep    = "false"
    oml_high_load             = var.oml_high_load
    oml_s3_access_key         = var.s3_access_key
    oml_s3_secret_key         = var.s3_secret_key
    oml_google_maps_api_key   = var.google_maps_api_key
    oml_google_maps_center    = var.google_maps_center
    oml_upgrade_to_major      = var.upgrade_to_major
    oml_tenant                = var.customer
    oml_voice_host            = "${var.customer}-asterisk.${var.domain_name}"
    oml_data_host             = "${var.customer}-redis.${var.domain_name}"
  })
  source                                      = "./modules/ec2-no-elb"
  vpc_id                                      = data.terraform_remote_state.shared_state.outputs.vpc_id
  launch_config_key_name                      = data.terraform_remote_state.shared_state.outputs.ec2_key
  launch_config_instance_type                 = var.ec2_oml_size
  launch_config_image_id                      = data.aws_ami.ubuntu.id
  launch_config_root_block_device_volume_name = "/dev/sda1"
  launch_config_root_block_device_volume_size = var.customer_root_disk_size
  launch_config_root_block_device_volume_type = "gp3"
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
