resource "aws_security_group" "tenants_ec2_sg" {
  name        = "${module.tags.tags.prefix}-${module.tags.tags.environment}-${var.customer}-SG"
  vpc_id      = data.terraform_remote_state.shared_state.*.outputs.vpc_id[0]
  description = "${module.tags.tags.role} EC2 Instances Service SG"

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
    description     = "HTTPS between ${var.customer} ALB and ${var.customer} tenant"
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "Prometheus Node EXP"
  }
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Prometheus"
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


resource "aws_security_group" "redis_ec2_sg" {
  name        = "${module.tags.tags.prefix}-${module.tags.tags.environment}-${var.customer}-redis-SG"
  vpc_id      = data.terraform_remote_state.shared_state.*.outputs.vpc_id[0]
  description = "${module.tags.tags.role} EC2 Instances Service Redis SG"

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "Redis"
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "Prometheus Node EXP"
  }
  ingress {
    from_port   = 9121
    to_port     = 9121
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "Redis prometheus exporter"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-redis-SG"),
    map("role", "${module.tags.tags.environment}-${var.customer}-redis-SG")
  )
}

resource "aws_security_group" "asterisk_ec2_sg" {
  name        = "${module.tags.tags.prefix}-${module.tags.tags.environment}-${var.customer}-asterisk-SG"
  vpc_id      = data.terraform_remote_state.shared_state.*.outputs.vpc_id[0]
  description = "${module.tags.tags.role} EC2 Instances Service Asterisk SG"

  ingress {
    from_port   = 5160
    to_port     = 5161
    protocol    = "udp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "udp agents"
  }
  ingress {
    from_port   = 5060
    to_port     = 5060
    protocol    = "udp"
    cidr_blocks = var.pstn_trunks
    description = "udp trunks"
  }
  ingress {
    from_port   = 40000
    to_port     = 50000
    protocol    = "udp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "udp rtpengine"
  }
  ingress {
    from_port   = 40000
    to_port     = 50000
    protocol    = "udp"
    cidr_blocks = var.pstn_trunks
    description = "udp rtp PSTN"
  }
  ingress {
    from_port   = 5038
    to_port     = 5038
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "AMI"
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "Prometheus Node EXP"
  }
  ingress {
    from_port   = 9060
    to_port     = 9060
    protocol    = "udp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "Homer Heplify"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-asterisk-SG"),
    map("role", "${module.tags.tags.environment}-${var.customer}-asterisk-SG")
  )
}

# resource "aws_security_group" "observability_ec2_sg" {
#   name        = "${module.tags.tags.prefix}-${module.tags.tags.environment}-${var.customer}-observability-SG"
#   vpc_id      = data.terraform_remote_state.shared_state.*.outputs.vpc_id[0]
#   description = "${module.tags.tags.role} EC2 Instances Service Observability SG"

#   ingress {
#     from_port   = 9090
#     to_port     = 9090
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Prometheus"
#   }
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Prometheus"
#   }
#   ingress {
#     from_port   = 9060
#     to_port     = 9060
#     protocol    = "udp"
#     cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
#     description = "AMI"
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = merge(module.tags.tags,
#     map("Name", "${module.tags.tags.environment}-${var.customer}-observability-SG"),
#     map("role", "${module.tags.tags.environment}-${var.customer}-observability-SG")
#   )
# }


resource "aws_security_group" "wombat_ec2_sg" {
  name        = "${module.tags.tags.prefix}-${module.tags.tags.environment}-${var.customer}-wombat-SG"
  vpc_id      = data.terraform_remote_state.shared_state.*.outputs.vpc_id[0]
  description = "${module.tags.tags.role} EC2 Instances Service Wombat SG"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "Tomcat http"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-wombat-SG"),
    map("role", "${module.tags.tags.environment}-${var.customer}-wombat-SG")
  )
}
