data "template_file" "observability" {
  template = file("${path.module}/templates/observability.tpl") 
  vars = {
      oml_tz                  = var.TZ
      oml_deploytool_branch   = var.omldeploytool_branch
      oml_nic                 = var.instance_nic
      oml_infras_stage        = var.cloud_provider
      oml_redis_host          = "${var.customer}-redis.${var.domain_name}"
      oml_voice_host          = "${var.customer}-asterisk.${var.domain_name}"
      oml_app_host            = "${var.customer}-app.${var.domain_name}"
    }
 }

resource "aws_instance" "observability" {
  ami                                   = data.aws_ami.ubuntu.id
  instance_type                         = var.ec2_observability_size
  subnet_id                             = data.terraform_remote_state.shared_state.outputs.private_subnet_ids[0]
  associate_public_ip_address           = true
  iam_instance_profile                  = aws_iam_instance_profile.test_profile.name
  user_data                             = base64encode(data.template_file.observability.rendered)
  vpc_security_group_ids                = [aws_security_group.observability_ec2_sg.id]

  root_block_device {
    volume_size           = var.observability_root_disk_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${module.tags.tags.environment}-${var.customer}-observability-EC2"
  }
  
}