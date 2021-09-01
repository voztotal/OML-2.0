module "tags" {
  source      = "./modules/tags"
  prefix      = "oml"
  name        = "testing-demo-freetech"
  environment = var.environment
  costCenter  = var.customer
  role        = "default"
  tagVersion  = "0.1.0"
  owner       = var.owner
  project     = "oml"
}
