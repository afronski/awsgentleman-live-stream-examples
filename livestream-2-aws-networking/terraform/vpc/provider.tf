terraform {
  required_version = "~> 0.12.0"
  backend "s3" {
    encrypt        = true
    bucket         = "terraform-state-storage"
    dynamodb_table = "terraform_state_lock"
    key            = "state-lock-storage.keypath"
    region         = "eu-north-1"
    profile        = "pattern-match-aws-gentleman"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
  profile = "pattern-match-aws-gentleman"
}
