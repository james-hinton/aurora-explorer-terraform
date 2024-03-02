resource "aws_s3_bucket" "aurora_data" {
  bucket = "aurora-explorer-data"

  tags = {
    Project = "Aurora Explorer"
  }
}

resource "aws_s3_bucket_public_access_block" "aurora_data_public_access_block" {
  bucket                  = aws_s3_bucket.aurora_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
