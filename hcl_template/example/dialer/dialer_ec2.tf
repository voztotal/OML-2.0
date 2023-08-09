# resource "aws_iam_role_policy" "dialer_ec2_ssm_management" {
#   name   = "${var.customer}DialerSsmManagement"
#   role   = module.dialer_ec2.iam_role_id
#   policy = templatefile("${path.module}/templates/ec2_ssm_policy.tpl", {})
# }

resource "aws_instance" "dialer_ec2" {
  ami                                   = data.aws_ami.amazon-linux-2.id
  instance_type                         = var.ec2_dialer_size
  subnet_id                             = data.terraform_remote_state.shared_state.outputs.private_subnet_ids[0]
  associate_public_ip_address           = false
  iam_instance_profile                  = aws_iam_instance_profile.test_profile.name
  vpc_security_group_ids                = [aws_security_group.wombat_ec2_sg.id]
  user_data                             = base64encode(data.template_file.dialer.rendered)

  root_block_device {
    volume_size           = var.customer_root_disk_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${module.tags.tags.environment}-${var.customer}-dialer-EC2"
  }
}

data "template_file" "dialer" {
  template = file("${path.module}/templates/dialer_install.tpl")
  vars = {
    customer       = var.customer
    wombat_version = var.wombat_version
    mysql_host     = local.mysql_host
    mysql_database = var.mysql_database
    mysql_username = var.mysql_username
    mysql_password = var.mysql_password
    TZ             = var.TZ
  }
}

