locals {
  mysql_host            = module.rds_mysql.address
  dialer_host           = aws_route53_record.wdint_dns.fqdn
  ec2_target_group_arns = [module.alb.default_target_group_arn, module.wombat_nlb.default_target_group_arn]
  backup_resources      = [module.rds_postgres.arn, module.rds_mysql.arn]
}
