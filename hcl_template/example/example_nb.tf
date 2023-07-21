data "aws_route53_zone" "selected" {
  name = var.domain_name
}

module "nlb" {
  source                                  = "./modules/terraform-aws-nlb"
  stage                                   = module.tags.environment
  name                                    = "${var.owner}-${var.customer}-nlb"
  vpc_id                                  = data.terraform_remote_state.shared_state.outputs.vpc_id
  subnet_ids                              = data.terraform_remote_state.shared_state.outputs.public_subnet_ids
  internal                                = false
  load_balancer_type                      = "network"
  target_group_name                       = "${var.customer}-httpsTG"
  target_group_port                       = 4573
  target_group_protocol                   = "TCP"
  target_group_target_type                = "instance"
  health_check_protocol                   = "TCP"
  health_check_port                       = 4573
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-NLB"),
    map("role", "${module.tags.tags.environment}-${var.customer}-NLB")
  )
}

resource "aws_route53_record" "nlb_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.customer}.${var.domain_name}"
  type    = "A"
  alias {
    name                   = module.nlb.nlb_dns_name
    zone_id                = module.nlb.nlb_zone_id
    evaluate_target_health = true
  }
}
