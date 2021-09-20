data "template_file" "redis" {
  template = file("${path.module}/templates/redis.tpl") 
  vars = {
      oml_infras_stage  = var.cloud_provider
      oml_nic           = var.instance_nic
      oml_redis_release = var.oml_redis_branch
    }
 }

resource "aws_instance" "redis" {
  ami                                   = data.aws_ami.amazon-linux-2.id
  instance_type                         = var.ec2_redis_size
  subnet_id                             = data.terraform_remote_state.shared_state.outputs.private_subnet_ids[0]
  associate_public_ip_address           = false
  iam_instance_profile                  = aws_iam_instance_profile.test_profile.name
  user_data                             = base64encode(data.template_file.redis.rendered) #file("omnileads-deploy/rredis.tpl") 
  vpc_security_group_ids                = [aws_security_group.redis_ec2_sg.id]
  tags = {
    Name = "${module.tags.tags.environment}-${var.customer}-redis-EC2"
  }
}