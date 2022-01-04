############################## bucket for callrec #####################################################
resource "aws_s3_bucket" "customer_data" {
  bucket = "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data"
  acl    = "private"
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data"),
    map("role", "${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-data")
  )
}

resource "aws_instance" "asterisk" {
  ami                                   = data.aws_ami.amazon-linux-2.id
  instance_type                         = var.ec2_asterisk_size
  subnet_id                             = data.terraform_remote_state.shared_state.outputs.private_subnet_ids[0]
  associate_public_ip_address           = false
  iam_instance_profile                  = aws_iam_instance_profile.test_profile.name
  vpc_security_group_ids                = [aws_security_group.asterisk_ec2_sg.id]
  user_data                             = base64encode(data.template_file.asterisk.rendered)

  root_block_device {
    volume_size           = var.asterisk_root_size
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
      aws_region                = var.aws_region
      oml_nic                   = var.instance_nic
      iam_role_name             = module.ec2.iam_role_name
      oml_acd_release           = var.oml_acd_branch
      oml_tenant_name           = var.customer
      oml_redis_host            = "${var.customer}-redis.${var.domain_name}"
      oml_app_host              = format("%s.%s", var.customer, var.domain_name)
      oml_pgsql_host            = module.rds_postgres.address
      oml_pgsql_port            = 5432
      oml_pgsql_db              = var.pg_database
      oml_pgsql_user            = var.pg_username
      oml_pgsql_password        = var.pg_password
      oml_pgsql_cloud           = "false"
      oml_ami_user              = var.ami_user
      oml_ami_password          = var.ami_password
      oml_callrec_device        = var.callrec_storage
      s3_access_key             = var.s3_access_key
      s3_secret_key             = var.s3_secret_key
      s3url                     = "NULL"
      ast_bucket_name           = split(".", aws_s3_bucket.customer_data.bucket_domain_name)[0]
      nfs_host                  = "NULL"
      oml_backup_filename       = var.oml_acd_backup_filename
      oml_auto_restore          = var.oml_auto_restore
      oml_tz                    = var.TZ
    }
 }