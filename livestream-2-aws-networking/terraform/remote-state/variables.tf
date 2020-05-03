# Terraform State

variable "aws_region" {
  description = "name of the AWS region"
  default     = "eu-north-1"
}

variable "terraform_state_storage_name" {
  description = "name of the S3 bucket used for rempte Terraform backend"
  default     = "terraform-state-storage"
}

variable "terraform_state_lock_name" {
  description = "name of the DynamoDB table used for exclusive locking of remote Terraform backed"
  default     = "terraform_state_lock"
}
