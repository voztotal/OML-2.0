module "customer_tfstate" {
  source       = "./modules/tfstate"
  project_name = "${var.customer}-freetech-project"
  environment  = "prod"
  tags         = module.tags.tags
}
