module "acm_certificate" {
  source            = "./modules/tf-aws-acm"
  domain_name       = "${var.domain_name}"
  hosted_zone_id    = data.aws_route53_zone.selected.zone_id
  tags              = module.tags.tags
  wildcard_enable   = true
}
