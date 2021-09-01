data "terraform_remote_state" "shared_state" {
  backend = "s3"
  config = {
    bucket = "terraform-shared-kodex-fts-project-prod-tfstate" #terraform-${var.shared_env}-${var.owner}-project-prod-tfstate"
    key    = "terraform.tfstate"
    region = "${var.aws_default_region}"
  }
}

