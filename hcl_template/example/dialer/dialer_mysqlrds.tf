module "rds_mysql" {
  source = "./modules/tf-aws-rds"
  apply_immediately       = true
  subnet_ids              = data.terraform_remote_state.shared_state.outputs.private_subnet_ids
  vpc_id                  = data.terraform_remote_state.shared_state.outputs.vpc_id
  name                    = "${module.tags.tags.environment}-${var.customer}-dialer"
  db_name                 = var.mysql_database
  username                = var.mysql_username
  password                = var.mysql_password
  engine                  = "mysql"
  multi_az                = false
  master_instance_class   = var.mysql_rds_size
  backup_retention_period = 5
  security_group_ids      = [data.terraform_remote_state.shared_state.outputs.sg_rds_id]

  replica_count              = 0
  replica_security_group_ids = [data.terraform_remote_state.shared_state.outputs.sg_rds_id]
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-common-myrds"),
    map("role", "${module.tags.tags.environment}-common-myrds")
  )
}
