# data "aws_ami" "amazon-linux-2" {
#   most_recent = true
#   owners = ["amazon"]

#   filter {
#     name   = "owner-alias"
#     values = ["amazon"]
#   }

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-ebs"]
#   }
# }

data "aws_ami" "ubuntu" {

    most_recent = true
    owners = ["099720109477"]

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    
}


resource "aws_iam_role_policy" "astsbc_ec2_ssm_management" {
  name   = "AstsbcSsmManagement"
  role   = module.astsbc_ec2.iam_role_id
  policy = templatefile("${path.module}/templates/ec2_ssm_policy.tpl", {})
}

resource "aws_iam_role_policy" "astsbc_ec2_s3_access_management" {
  name = "AstsbcS3FullAccessManagement"
  role = module.astsbc_ec2.iam_role_id
  policy = templatefile("${path.module}/templates/s3_full_access_policy.tpl", {
    astsbc_s3_bucket = aws_s3_bucket.astsbc_configuration.arn
  })
}

resource "aws_iam_role_policy" "astsbc_eip_allocation" {
  name   = "AstsbcEipAllocationhManagement"
  role   = module.astsbc_ec2.iam_role_id
  policy = templatefile("${path.module}/templates/ec2_eip_allocation.tpl", {})
}

resource "aws_key_pair" "ec2" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDNVAC8P2ExZZzw0EQB6EJ/anI60VJXCfPYL2Q2pXQDAfNUz55ZeFiWXNvSZtvhjWv9nJIfIWJxNpZibQn8O26pp1PgEUcu5gB8/5qpB6LeRICjpeKBN61z01R+ro3KSSd7qKxFb6IsdymPBdaMB+KCrEbdDCtIHYj15DKBreprLZFmmmJMSR3grSQaW3p7hyS9oDB8KXu3kg5yO9A+jUhvNMAHezxnUWKF1CpmVy1eMcrzCQolCt2OxcJu+TIjSaR7pqgyoQnva0VYvv9bvMvOAMbbazjzHO4dLW4PFwnpvlpxHyj2JmjUmpZZCKQr4biNtS96E5h+mKzoo3OimeTjN8RCsyAwc29suN/0fr0pLiVKtHVUOmOUGQ1whpQrh3js9nXUB9WY2Iyp7KCfNiLTZY4l/z40aJ0HmK39SXX9E5QkpQsdytvCMSudegR9nMrqZHkqxTw0IBwLO+e7pak1HE+tZgDYcmmZmI2bVHpHI3sjdUpvyZKVmpLxhl4XS3k= fpignataro@fpignataro-UX430UNR"
}

module "astsbc_ec2" {

  source                                      = "./modules/ec2-no-elb"
  vpc_id                                      = module.networking.vpc_id
  launch_config_image_id                      = data.aws_ami.ubuntu.id
  launch_config_instance_type                 = var.ec2_size_astsbc
  launch_config_key_name                      = aws_key_pair.ec2.key_name
  launch_config_associate_public_ip_address   = true
  launch_config_enable_monitoring             = true
  launch_config_root_block_device_volume_size = var.disk_size_astsbc
  launch_config_root_block_device_volume_type = "gp2"
  asg_min_size                                = 1
  asg_max_size                                = 1
  asg_desired_capacity                        = 1
  asg_ec2_subnet_ids                          = module.networking.public_subnet_ids
  asg_target_group_arns                       = [module.astsbc_int_sip_nlb.default_target_group_arn]
  security_group_id                           = aws_security_group.astsbc_ec2_sg.id
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-astsbc-EC2"),
    map("role", "${module.tags.tags.environment}-${var.customer}-astsbc-EC2")
  )
  asg_tag_names = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-astsbc-EC2"),
    map("role", "${module.tags.tags.environment}-${var.customer}-astsbc-EC2")
  )
}

resource "aws_s3_bucket" "astsbc_configuration" {
  bucket = "${module.tags.tags.prefix}-${module.tags.tags.environment}-${module.tags.tags.owner}-${var.customer}-astsbc-configuration"
  acl    = "private"
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-astsbc-configuration"),
    map("role", "${module.tags.tags.environment}-${var.customer}-astsbc-configuration")
  )
}
