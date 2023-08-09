locals {
  mysql_host            = module.rds_mysql.address
  dialer_host           = "${var.customer}-dialer.${var.domain_name}"
  ec2_target_group_arns = [module.alb.default_target_group_arn]
  backup_resources      = [module.rds_postgres.arn, module.rds_mysql.arn]
}
