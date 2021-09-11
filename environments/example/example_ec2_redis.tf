resource "aws_iam_role" "test_role" {
  name = "test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "tag-value"
  }
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "A test policy"
  policy      = file("${path.module}/templates/ec2_ssm_policy.tpl") 
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = ["${aws_iam_role.test_role.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_instance_profile" "test_profile" {
  name  = "test_profile"
  roles = ["${aws_iam_role.test_role.name}"]
}


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