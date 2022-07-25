data "template_file" "websockets" {
  template = file("${path.module}/templates/websockets.tpl")
  vars = {
      oml_infras_stage          = var.cloud_provider
      oml_nic                   = var.instance_nic
      oml_ws_release            = var.oml_websockets_branch
      oml_ws_port               = "8000"
      oml_redis_host            = "${var.customer}-redis.${var.domain_name}"
      oml_redis_port            = "6379"
      oml_redis_cluster         = "false"
      oml_redis_sentinel_host_01= "NULL"
      oml_redis_sentinel_host_02= "NULL"
      oml_redis_sentinel_host_03= "NULL"
    }
 }

resource "aws_instance" "websockets" {
  ami                                   = data.aws_ami.ubuntu.id
  instance_type                         = var.ec2_kamailio_size
  subnet_id                             = data.terraform_remote_state.shared_state.outputs.private_subnet_ids[0]
  associate_public_ip_address           = false
  iam_instance_profile                  = aws_iam_instance_profile.test_profile.name
  user_data                             = base64encode(data.template_file.websockets.rendered)
  vpc_security_group_ids                = [aws_security_group.websockets_ec2_sg.id]
  tags = {
    Name = "${module.tags.tags.environment}-${var.customer}-websockets-EC2"
  }
}
