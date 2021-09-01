module "tfstate" {
  source       = "./modules/tfstate"
  project_name = "${var.customer}-${var.owner}-project"
  environment  = "prod"
  tags         = module.tags.tags
}
