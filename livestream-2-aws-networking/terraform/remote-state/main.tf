resource "aws_s3_bucket" "terraform_state_storage" {
  bucket = var.terraform_state_storage_name
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_storage_public_access_block" {
  bucket = aws_s3_bucket.terraform_state_storage.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name     = var.terraform_state_lock_name
  hash_key = "LockID"

  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "LockID"
    type = "S"
  }
}
