
module "ec2" {
  additional_user_data = templatefile("${path.module}/templates/omlapp.tpl", {
    ast_bucket_name           = split(".", aws_s3_bucket.customer_data.bucket_domain_name)[0]
    iam_role_name             = module.ec2.iam_role_name
    aws_region                = var.aws_region
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
    oml_app_release           = var.oml_app_branch
    oml_app_ecctl             = var.ECCTL
    oml_rtpengine_host        = data.terraform_remote_state.shared_state.outputs.rtpengine_fqdn
    oml_app_sca               = var.SCA
    vpc_subnet                = data.terraform_remote_state.shared_state.outputs.vpc_cidr_block
    oml_tz                    = var.TZ
    oml_infras_stage          = var.cloud_provider
    oml_tenant_name           = var.customer
    oml_callrec_device        = var.callrec_storage
    s3_access_key             = var.s3_access_key
    s3_secret_key             = var.s3_secret_key
    s3url                     = "NULL"
    s3_bucket_name            = "NULL"
    nfs_host                  = "NULL"
    optoml_device             = "NULL"
    pgsql_device              = "NULL"
    oml_nic                   = var.instance_nic
    oml_acd_host              = "${var.customer}-asterisk.${var.domain_name}"
    oml_kamailio_host         = "${var.customer}-kamailio.${var.domain_name}"
    oml_redis_host            = "${var.customer}-redis.${var.domain_name}"
    oml_websocket_host        = "NULL"
    oml_websocket_port        = "NULL"
    oml_extern_ip             = "auto"
    oml_app_login_fail_limit  = 10
    oml_app_init_env          = "true"
    oml_app_reset_admin_pass  = "true"
    oml_app_install_sngrep    = "true"
  })
  source                                      = "./modules/ec2-no-elb"
  vpc_id                                      = data.terraform_remote_state.shared_state.outputs.vpc_id
  launch_config_key_name                      = data.terraform_remote_state.shared_state.outputs.ec2_key
  launch_config_instance_type                 = var.ec2_oml_size
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
