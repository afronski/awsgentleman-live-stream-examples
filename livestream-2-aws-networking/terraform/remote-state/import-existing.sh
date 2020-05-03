#!/usr/bin/env bash

terraform import aws_s3_bucket.terraform_state_storage "terraform-state-storage"
terraform import aws_dynamodb_table.terraform_state_lock "terraform_state_lock"
