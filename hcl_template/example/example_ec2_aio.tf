resource "aws_s3_bucket" "customer_data" {
  bucket = "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data"
  acl    = "private"
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data"),
    map("role", "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data")
  )
}

resource "aws_instance" "omlapp" {
  ami                                   = data.aws_ami.ubuntu.id
  instance_type                         = var.ec2_oml_size
  subnet_id                             = data.terraform_remote_state.shared_state.outputs.private_subnet_ids[0]
  associate_public_ip_address           = false
  iam_instance_profile                  = aws_iam_instance_profile.test_profile.name
  vpc_security_group_ids                = [aws_security_group.tenants_ec2_sg.id, aws_security_group.asterisk_ec2_sg.id]  
  user_data                             = base64encode(data.template_file.omlapp.rendered)

  root_block_device {
    volume_size           = var.customer_root_disk_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${module.tags.tags.environment}-${var.customer}-omlapp-EC2"
  }
}

data "template_file" "omlapp" {
  template = file("${path.module}/templates/aio.tpl")
  vars = {
    bucket_name               = split(".", aws_s3_bucket.customer_data.bucket_domain_name)[0]
    oml_deploytool_branch     = var.omldeploytool_branch
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
    oml_app_tag               = var.oml_app_branch
    oml_app_ecctl             = var.ECCTL
    oml_rtpengine_host        = data.terraform_remote_state.shared_state.outputs.rtpengine_fqdn
    obs_host                  = var.obs_host
    oml_app_sca               = var.SCA
    vpc_subnet                = data.terraform_remote_state.shared_state.outputs.vpc_cidr_block
    oml_tz                    = var.TZ
    oml_infras_stage          = var.cloud_provider
    oml_tenant_name           = var.customer
    oml_app_login_fail_limit  = 10
    oml_google_maps_api_key   = var.google_maps_api_key
    oml_google_maps_center    = var.google_maps_center
    oml_upgrade_to_major      = var.upgrade_to_major
    oml_tenant                = var.customer
    oml_s3_access_key         = var.s3_access_key
    oml_s3_secret_key         = var.s3_secret_key
    scale_asterisk            = var.scale_asterisk
    scale_uwsgi               = var.scale_uwsgi
  }
}

