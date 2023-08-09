resource "aws_instance" "redis" {
  ami                                   = data.aws_ami.ubuntu.id
  instance_type                         = var.ec2_redis_size
  subnet_id                             = data.terraform_remote_state.shared_state.outputs.private_subnet_ids[0]
  associate_public_ip_address           = false
  iam_instance_profile                  = aws_iam_instance_profile.test_profile.name
  vpc_security_group_ids                = [aws_security_group.redis_ec2_sg.id]
  user_data                             = base64encode(data.template_file.redis.rendered)

  root_block_device {
    volume_size           = var.redis_root_disk_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${module.tags.tags.environment}-${var.customer}-redis-EC2"
  }
}

data "template_file" "redis" {
  template = file("${path.module}/templates/redis.tpl")
  vars = {
      oml_infras_stage          = var.cloud_provider
      oml_deploytool_branch     = var.omldeploytool_branch
      aws_region                = var.aws_region
      oml_tenant_name           = var.customer
      oml_data_host             = "${var.customer}-redis.${var.domain_name}"
      oml_pgsql_host            = module.rds_postgres.address
      oml_pgsql_cloud           = "false"
      oml_tz                    = var.TZ
      oml_tenant                = var.customer
      oml_obs_host              = var.obs_host
    }
 }
