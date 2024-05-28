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
      oml_tenant_name           = var.customer
      oml_app_host              = "${var.customer}-omlapp.${var.domain_name}"
      oml_data_host             = "${var.customer}-redis.${var.domain_name}"      
      oml_upgrade_to_major      = var.upgrade_to_major
      oml_app_host              = "${var.customer}-omlapp.${var.domain_name}"
      oml_data_host             = "${var.customer}-redis.${var.domain_name}"
      oml_rtpengine_host        = data.terraform_remote_state.shared_state.outputs.rtpengine_fqdn
      oml_obs_host              = var.obs_host
      oml_ami_user              = var.ami_user
      oml_ami_password          = var.ami_password
      oml_callrec_device        = var.callrec_storage
      oml_tz                    = var.TZ
      oml_tenant                = var.customer
      scale_asterisk            = var.scale_asterisk
    }
 }
