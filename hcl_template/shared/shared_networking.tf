data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "rds_sg" {
  name        = "${module.tags.tags.prefix}-${module.tags.tags.environment}-rds-SG"
  description = "Allow database traffic with tenant"
  vpc_id      = module.networking.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = module.networking.private_subnets_cidr_blocks
    description = "Postgres open to all private networks"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = module.networking.private_subnets_cidr_blocks
    description = "MySQL open to all private networks"
  }
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-databasesSG"),
    map("role", "${module.tags.tags.environment}-${var.customer}-databasesSG")
  )
}

resource "aws_security_group" "rtpengine_ec2_sg" {
  name        = "${module.tags.tags.prefix}-${module.tags.tags.environment}-${var.customer}-rtpengine-SG"
  vpc_id      = module.networking.vpc_id
  description = "${module.tags.tags.role} EC2 Instances Service SG"

  ingress {
    from_port   = 22222
    to_port     = 22222
    protocol    = "udp"
    cidr_blocks = module.networking.private_subnets_cidr_blocks
    description = "NGC between rtpengine and OML kamailio"
  }
  ingress {
    from_port   = 20000
    to_port     = 60000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "RTP between rtpengine and the world"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-rtpengine-SG"),
    map("role", "${module.tags.tags.environment}-${var.customer}-rtpengine-SG")
  )
}

resource "aws_security_group" "astsbc_ec2_sg" {
  name        = "${module.tags.tags.prefix}-${module.tags.tags.environment}-${var.customer}-astsbc-SG"
  vpc_id      = module.networking.vpc_id
  description = "${module.tags.tags.role} EC2 Instances Service SG"

  ingress {
    from_port   = 5060
    to_port     = 5060
    protocol    = "udp"
    cidr_blocks = var.pstn_trunks
    description = "SIP between SBC and PSTN"
  }
  ingress {
    from_port   = 6060
    to_port     = 6060
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SIP between SBC and TENANTS"
  }
  ingress {
    from_port   = 20000
    to_port     = 60000
    protocol    = "udp"
    cidr_blocks = var.pstn_trunks
    description = "RTP between SBC and TENANTS and PSTN"
  }  
  ingress {
    from_port   = 20000
    to_port     = 60000
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "RTP between SBC and TENANTS and PSTN"
  }    
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-astsbc-SG"),
    map("role", "${module.tags.tags.environment}-${var.customer}-astsbc-SG")
  )
}

resource "aws_eip" "rtpengine_eip" {
  vpc = true
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-rtpengineEIP"),
    map("role", "${module.tags.tags.environment}-${var.customer}-rtpengineEIP")
  )
}

resource "aws_eip" "astsbc_eip" {
  vpc = true
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-astsbcEIP"),
    map("role", "${module.tags.tags.environment}-${var.customer}-astsbcEIP")
  )
}

module "networking" {
  source     = "./modules/networking"
  azs_list   = ["${data.aws_availability_zones.available.names[0]}", "${data.aws_availability_zones.available.names[1]}"]
  cidr_block = "10.0.0.0/16"
  newbits    = 4
  tags = merge(module.tags.tags,
    map("role", "${module.tags.tags.environment}-${module.tags.tags.costCenter}-vpc")
  )
}

resource "aws_key_pair" "ec2" {
  key_name   = "deployer-key"
  public_key = var.aws_ssh_key
}
