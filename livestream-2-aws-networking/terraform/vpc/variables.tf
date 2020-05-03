# AWS VPC

variable "aws_region" {
  description = "name of the AWS region"
  default     = "eu-north-1"
}

variable "name" {
  description = "name of the VPC"
  default     = "tf-0.12-main-vpc"
}

variable "vpc_CIDR" {
  description = "CIDR for the VPC in IPv4 range"
  default     = "10.20.0.0/16"
}

variable "public_subnets_CIDRs" {
  description = "list of CIDRs for public subnets"
  type        = "list"
  default = [
    "10.20.2.0/24",
    "10.20.4.0/24"
  ]
}

variable "private_subnets_CIDRs" {
  description = "list of CIDRs for private subnets"
  type        = "list"
  default = [
    "10.20.1.0/24",
    "10.20.3.0/24"
  ]
}

variable "zones_for_public_subnets" {
  description = "list of AWS Availability Zones used for public subnets"
  type        = "list"
  default = [
    "eu-north-1a",
    "eu-north-1b"
  ]
}

variable "zones_for_private_subnets" {
  description = "list of AWS Availability Zones used for private subnets"
  type        = "list"
  default = [
    "eu-north-1a",
    "eu-north-1b"
  ]
}
