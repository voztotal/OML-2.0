data "aws_route53_zone" "selected" {
  name         = var.domain_name
}

module "alb" {
  source                                  = "./modules/terraform-aws-alb"
  stage                                   = module.tags.environment
  name                                    = "${var.owner}-${var.customer}-alb"
  vpc_id                                  = data.terraform_remote_state.shared_state.outputs.vpc_id
  subnet_ids                              = data.terraform_remote_state.shared_state.outputs.public_subnet_ids
  http_enabled                            = false
  alb_access_logs_s3_bucket_force_destroy = true
  access_logs_region                      = var.aws_region
  http2_enabled                           = true
  https_enabled                           = true
  idle_timeout                            = 600
  certificate_arn                         = data.terraform_remote_state.shared_state.outputs.acm_arn
  target_group_name                       = "${var.customer}-httpsTG"
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

# esto no lo hago para nginx y prometheus, ya que se lo indica a nivel
# module de ec2 autoscalling.
# resource "aws_lb_target_group_attachment" "homer" {
#   target_group_arn = module.alb.homer_target_group_arn
#   target_id        = aws_instance.asterisk.id
#   port             = 80
# }

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


# data "aws_route53_zone" "selected" {
#   name         = "${var.domain_name}-prom"
# }


module "alb_prom" {
  source                                  = "./modules/terraform-aws-alb"
  stage                                   = module.tags.environment
  name                                    = "${var.owner}-${var.customer}-alb-prom"
  vpc_id                                  = data.terraform_remote_state.shared_state.outputs.vpc_id
  subnet_ids                              = data.terraform_remote_state.shared_state.outputs.public_subnet_ids
  http_enabled                            = false
  alb_access_logs_s3_bucket_force_destroy = true
  access_logs_region                      = var.aws_region
  http2_enabled                           = true
  https_enabled                           = true
  idle_timeout                            = 600
  certificate_arn                         = data.terraform_remote_state.shared_state.outputs.acm_arn
  target_group_name                       = "${var.customer}-prometheus"
  target_group_protocol                   = "HTTP"
  target_group_target_type                = "instance"
  target_group_port                       = 9090
  health_check_port                       = 9090
  health_check_protocol                   = "HTTP"
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-ALB-PROM"),
    map("role", "${module.tags.tags.environment}-${var.customer}-ALB-PROM")
  )
}

# esto no lo hago para nginx y prometheus, ya que se lo indica a nivel
# module de ec2 autoscalling.
# resource "aws_lb_target_group_attachment" "homer" {
#   target_group_arn = module.alb.homer_target_group_arn
#   target_id        = aws_instance.asterisk.id
#   port             = 80
# }

resource "aws_route53_record" "alb_prom_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.customer}.${var.domain_name}-prom"
  type    = "A"
  alias {
    name                   = module.alb_prom.alb_dns_name
    zone_id                = module.alb_prom.alb_zone_id
    evaluate_target_health = true
  }
}