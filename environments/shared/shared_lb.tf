module "astsbc_int_sip_nlb" {
  source                                  = "./modules/terraform-aws-nlb"
  stage                                   = module.tags.environment
  name                                    = "${var.customer}-intsbcNBL"
  vpc_id                                  = module.networking.vpc_id
  subnet_ids                              = module.networking.private_subnet_ids
  access_logs_enabled                     = false
  nlb_access_logs_s3_bucket_force_destroy = true
  internal                                = true
  health_check_port                       = 7088
  health_check_protocol                   = "TCP"
  health_check_interval                   = 30
  target_group_name                       = "${module.tags.environment}-${var.customer}-intsbcTG"
  target_group_port                       = 6060
  tcp_enabled                             = false
  udp_enabled                             = true
  udp_port                                = 6060
  target_group_target_type                = "instance"
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-intsbcNBL"),
    map("role", "${module.tags.tags.environment}-${var.customer}-intsbcNBL")
  )
}
