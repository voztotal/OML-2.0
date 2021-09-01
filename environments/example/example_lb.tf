data "aws_route53_zone" "selected" {
  name         = "${var.domain_name}"
}

module "alb" {
  source                                  = "./modules/terraform-aws-alb"
  stage                                   = module.tags.environment
  name                                    = "${var.customer}-alb"
  vpc_id                                  = data.terraform_remote_state.shared_state.outputs.vpc_id
  subnet_ids                              = data.terraform_remote_state.shared_state.outputs.public_subnet_ids
  http_enabled                            = false
  alb_access_logs_s3_bucket_force_destroy = true
  access_logs_region                      = var.aws_region
  http2_enabled                           = true
  https_enabled                           = true
  idle_timeout                            = 600
  certificate_arn                         = data.terraform_remote_state.shared_state.outputs.acm_arn
  target_group_name                       = "${module.tags.tags.environment}-${var.customer}-httpsTG"
  target_group_protocol                   = "HTTPS"
  target_group_target_type                = "instance"
  target_group_port                       = 443
  health_check_port                       = 443
  health_check_protocol                   = "HTTPS"
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-ALB"),
    map("role", "${module.tags.tags.environment}-${var.customer}-ALB")
  )
}

resource "aws_lb_listener_rule" "alb_ingress" {
  listener_arn = module.alb.https_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.alb.default_target_group_arn
  }

  condition {
    field  = "host-header"
    values = ["${var.customer}.${var.domain_name}"]
  }
}

resource "aws_route53_record" "alb_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.customer}.${var.domain_name}"
  type    = "A"
  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}
