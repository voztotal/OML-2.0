module "rds_postgres" {
  source                     = "./modules/tf-aws-rds"
  apply_immediately          = true
  subnet_ids                 = data.terraform_remote_state.shared_state.outputs.private_subnet_ids
  vpc_id                     = data.terraform_remote_state.shared_state.outputs.vpc_id
  name                       = "${module.tags.tags.environment}-${var.customer}"
  db_name                    = var.pg_database
  username                   = var.pg_username
  password                   = var.pg_password
  engine                     = "postgres"
  postgres_engine_version    = "11.18"
  backup_retention_period    = 5
  security_group_ids         = [data.terraform_remote_state.shared_state.outputs.sg_rds_id]
  multi_az                   = false
  master_instance_class      = var.pg_rds_size
  replica_count              = 0
  replica_security_group_ids = [data.terraform_remote_state.shared_state.outputs.sg_rds_id]
  tags = merge(module.tags.tags,
    map("Name", "${module.tags.tags.environment}-${var.customer}-pgrds"),
    map("role", "${module.tags.tags.environment}-${var.customer}-pgrds")
  )
}
