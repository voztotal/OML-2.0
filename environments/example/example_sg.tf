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
    from_port   = 5162
    to_port     = 5162
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

resource "aws_security_group" "kamailio_ec2_sg" {
  name        = "${module.tags.tags.prefix}-${module.tags.tags.environment}-${var.customer}-kamailio-SG"
  vpc_id      = data.terraform_remote_state.shared_state.*.outputs.vpc_id[0]
  description = "${module.tags.tags.role} EC2 Instances Service Kamailio SG"

  ingress {
    from_port   = 5060
    to_port     = 5060
    protocol    = "udp"
    cidr_blocks = [data.terraform_remote_state.shared_state.outputs.vpc_cidr_block]
    description = "kamailio SIP UDP"
  }
  ingress {
    from_port   = 14443
    to_port     = 14443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "kamailio SIP WSS"
  }  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-kamailio-SG"),
    map("role", "${module.tags.tags.environment}-${var.customer}-kamailio-SG")
  )
}
