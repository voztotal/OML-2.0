terraform {
  required_version = "~> 0.12.9"
  backend "s3" {
    bucket  = "terraform-hermetica-fts-project-prod-tfstate"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = "true"
  }
}
