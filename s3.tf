resource "aws_s3_bucket" "aurora_data" {
  bucket = "aurora-explorer-data"

  tags = {
    Project = "Aurora Explorer"
  }
}

resource "aws_s3_bucket_acl" "aurora_data_acl" {
  bucket = aws_s3_bucket.aurora_data.id
  acl    = "private"
}
