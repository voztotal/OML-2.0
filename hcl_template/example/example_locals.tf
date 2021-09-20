locals {
  mysql_host            = null
  dialer_host           = null
  ec2_target_group_arns = [module.alb.default_target_group_arn]
  backup_resources      = [module.rds_postgres.arn]
}
