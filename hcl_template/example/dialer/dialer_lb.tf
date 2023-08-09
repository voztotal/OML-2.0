module "default_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  attributes = []
  delimiter  = "-"
  name       = "${var.owner}-${var.customer}-dialer"
  namespace  = ""
  stage      = ""
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-ALB"),
    map("role", "${module.tags.tags.environment}-${var.customer}-ALB")
  )
}


resource "aws_security_group" "wombat_lb_sg" {
  description = "Controls access to the ALB (HTTP/HTTPS)"
  vpc_id      = data.terraform_remote_state.shared_state.outputs.vpc_id
  name        = module.default_label.id
  tags        = module.default_label.tags
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.wombat_lb_sg.id
}

resource "aws_security_group_rule" "http_ingress_wombat" {
  type              = "ingress"
  from_port         = 443
  to_port           = 444
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  #prefix_list_ids   = var.http_ingress_prefix_list_ids
  security_group_id = aws_security_group.wombat_lb_sg.id
}


# Crear el recurso del ALB
resource "aws_lb" "dialer" {
  name               = module.default_label.id
  tags               = module.default_label.tags
  internal           = false
  load_balancer_type = "application"

  security_groups     = [aws_security_group.wombat_lb_sg.id]

  subnets                          = data.terraform_remote_state.shared_state.outputs.public_subnet_ids
  enable_http2                     = true
  idle_timeout                     = 600
  #ip_address_type                  = var.ip_address_type
  enable_deletion_protection       = false
}

resource "aws_lb_target_group" "wombat" {
  name                 = "${var.customer}-WDadmin"
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = data.terraform_remote_state.shared_state.outputs.vpc_id
  target_type          = "instance"
  deregistration_delay = 1800

  health_check {
    path                = "/"
    port                = 8080
    protocol            = "HTTP"
    timeout             = 60
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 100
    #matcher             = 
  }

  lifecycle {
    create_before_destroy = true
  }

  # tags = merge(
  #   module.default_target_group_label.tags,
  #   var.target_group_additional_tags
  # )
}


module "default_target_group_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  attributes = ["default"]
  delimiter  = "-"
  name       = "${var.owner}-${var.customer}-dialer"
  namespace  = ""
  stage      = ""
  tags       = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-ALB"),
    map("role", "${module.tags.tags.environment}-${var.customer}-ALB")
  )
}



resource "aws_lb_listener" "https" {
  #count             = var.https_enabled ? 1 : 0
  load_balancer_arn = aws_lb.dialer.arn

  port            = 443
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.terraform_remote_state.shared_state.outputs.acm_arn

  default_action {
    target_group_arn = aws_lb_target_group.wombat.arn
    type             = "forward"
  }
}



# Agregar instancia EC2 al target group
resource "aws_lb_target_group_attachment" "target_group_attachment" {
  target_group_arn = aws_lb_target_group.wombat.arn
  target_id        = aws_instance.dialer_ec2.id
  port             = 8080
}



resource "aws_route53_record" "wdext_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.customer}-wdext.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.dialer.dns_name
    zone_id                = aws_lb.dialer.zone_id
    evaluate_target_health = false
  }
}
