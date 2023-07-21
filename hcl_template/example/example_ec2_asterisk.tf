resource "aws_instance" "asterisk" {
  ami                                   = data.aws_ami.ubuntu.id
  instance_type                         = var.ec2_asterisk_size
  subnet_id                             = data.terraform_remote_state.shared_state.outputs.private_subnet_ids[0]
  associate_public_ip_address           = false
  iam_instance_profile                  = aws_iam_instance_profile.test_profile.name
  vpc_security_group_ids                = [aws_security_group.asterisk_ec2_sg.id]
  user_data                             = base64encode(data.template_file.asterisk.rendered)

  root_block_device {
    volume_size           = var.asterisk_root_disk_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${module.tags.tags.environment}-${var.customer}-asterisk-EC2"
  }
}

data "template_file" "asterisk" {
  template = file("${path.module}/templates/asterisk.tpl")
  vars = {
      oml_infras_stage          = var.cloud_provider
      oml_deploytool_branch     = var.omldeploytool_branch
      aws_region                = var.aws_region
      iam_role_name             = module.ec2.iam_role_name
      oml_acd_release           = var.oml_acd_branch
      oml_tenant_name           = var.customer
      oml_app_host              = "${var.customer}.${var.domain_name}"
      oml_data_host            = "${var.customer}-redis.${var.domain_name}"
      oml_pgsql_host            = module.rds_postgres.address
      oml_pgsql_port            = 5432
      oml_pgsql_db              = var.pg_database
      oml_pgsql_user            = var.pg_username
      oml_upgrade_to_major      = var.upgrade_to_major
      oml_app_host              = "${var.customer}.${var.domain_name}"
      oml_data_host             = "${var.customer}-redis.${var.domain_name}"
      oml_rtpengine_host        = data.terraform_remote_state.shared_state.outputs.rtpengine_fqdn
      oml_obs_host              = var.obs_host
      oml_pgsql_password        = var.pg_password
      oml_pgsql_cloud           = "false"
      oml_ami_user              = var.ami_user
      oml_ami_password          = var.ami_password
      oml_callrec_device        = var.callrec_storage
      bucket_name               = split(".", aws_s3_bucket.customer_data.bucket_domain_name)[0]
      bucket_access_key         = var.s3_access_key
      bucket_secret_key         = var.s3_secret_key
      oml_tz                    = var.TZ
      oml_tenant                = var.customer
    }
 }
