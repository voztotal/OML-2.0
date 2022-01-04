data "template_file" "kamailio" {
  template = file("${path.module}/templates/kamailio.tpl") 
  vars = {
      oml_infras_stage          = var.cloud_provider
      oml_nic                   = var.instance_nic
      oml_kamailio_release      = var.oml_kamailio_branch
      oml_rtpengine_host        = data.terraform_remote_state.shared_state.outputs.rtpengine_fqdn
      oml_redis_host            = "${var.customer}-redis.${var.domain_name}"
      oml_acd_host              = "${var.customer}-asterisk.${var.domain_name}"
      oml_kamailio_host         = "${var.customer}-kamailio.${var.domain_name}"
      oml_kamailio_pkg_size     = var.kamailio_pkg_size
      oml_kamailio_shm_size     = var.kamailio_shm_size
    }
 }

resource "aws_instance" "kamailio" {
  ami                                   = data.aws_ami.amazon-linux-2.id
  instance_type                         = var.ec2_kamailio_size
  subnet_id                             = data.terraform_remote_state.shared_state.outputs.private_subnet_ids[0]
  associate_public_ip_address           = false
  iam_instance_profile                  = aws_iam_instance_profile.test_profile.name
  user_data                             = base64encode(data.template_file.kamailio.rendered)
  vpc_security_group_ids                = [aws_security_group.kamailio_ec2_sg.id]

  root_block_device {
    volume_size           = var.kamailio_root_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${module.tags.tags.environment}-${var.customer}-kamailio-EC2"
  }
  
}