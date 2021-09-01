resource "aws_security_group" "tenants_ec2_sg" {
  name        = "${module.tags.tags.prefix}-${module.tags.tags.environment}-${var.customer}-SG"
  vpc_id      = data.terraform_remote_state.shared_state.*.outputs.vpc_id[0]
  description = "${module.tags.tags.role} EC2 Instances Service SG"

  ingress {
    from_port       = 5160
    to_port         = 5162
    protocol        = "udp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description     = "SIP between OML asterisk and SBC"
  }
  ingress {
    from_port   = 5038
    to_port     = 5038
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "Asterisk AMI"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "Internal SSH"
  }
  ingress {
    from_port       = 10000
    to_port         = 50000
    protocol        = "udp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description     = "RTP between OML asterisk and SBC"
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
    description     = "HTTPS between ${var.customer} ALB and ${var.customer} tenant"
  }
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description     = "HTTP between OML ${var.customer} tenant and dialer ALB"
  }
  ingress {
    from_port       = 7088
    to_port         = 7088
    protocol        = "tcp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description     = "HTTP between OML ${var.customer} asterisk and dialer NLB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-SG"),
    map("role", "${module.tags.tags.environment}-${var.customer}-SG")
  )
}
