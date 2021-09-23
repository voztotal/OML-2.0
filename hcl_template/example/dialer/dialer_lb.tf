resource "aws_lb_listener_rule" "wd_external_ingress" {
  listener_arn = module.alb.https_listener_arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wdext_target_group.arn
  }

  condition {
    field  = "host-header"
    values = [aws_route53_record.wdext_dns.fqdn]
  }
}

resource "aws_lb_target_group" "wdint_target_group" {
  name        = "${module.tags.tags.environment}-${var.customer}-wdintTG"
  port        = 8080
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.shared_state.outputs.vpc_id
  stickiness {
    enabled = false
    type = "lb_cookie"
  }
  health_check {
    port                = "8080"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "wdext_target_group" {
  name        = "${module.tags.tags.environment}-${var.customer}-wdextTG"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.shared_state.outputs.vpc_id

  health_check {
    path                = "/"
    port                = "8080"
    healthy_threshold   = 3
    unhealthy_threshold = 5
    matcher             = "200"
  }
}

module "wombat_nlb" {
  source                                  = "./modules/terraform-aws-nlb"
  namespace                               = module.tags.prefix
  stage                                   = module.tags.environment
  name                                    = "${var.customer}-wdNLB"
  vpc_id                                  = data.terraform_remote_state.shared_state.outputs.vpc_id
  subnet_ids                              = data.terraform_remote_state.shared_state.outputs.private_subnet_ids
  internal                                = true
  access_logs_enabled                     = false
  nlb_access_logs_s3_bucket_force_destroy = true
  health_check_port                       = 7088
  health_check_protocol                   = "HTTP"
  health_check_interval                   = 30
  target_group_name                       = "${module.tags.environment}-${var.customer}-amiTG"
  target_group_port                       = 5038
  tcp_port                                = 5038
  target_group_target_type                = "instance"
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-wdNLB"),
    map("role", "${module.tags.tags.environment}-${var.customer}-wdNLB")
  )
}

resource "aws_lb_listener" "wd_internal_listener" {
  load_balancer_arn = module.wombat_nlb.nlb_arn
  port              = "8080"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wdint_target_group.arn
  }
}

resource "aws_route53_record" "wdint_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.customer}-wdint.${var.domain_name}"
  type    = "A"
  alias {
    name                   = module.wombat_nlb.nlb_dns_name
    zone_id                = module.wombat_nlb.nlb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "wdext_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.customer}-wdext.${var.domain_name}"
  type    = "A"
  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = false
  }
}
