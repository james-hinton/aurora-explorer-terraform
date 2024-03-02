resource "aws_dynamodb_table" "hpi_data" {
  name           = "HPI_Data"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Date"

  attribute {
    name = "Date"
    type = "S"
  }

  tags = {
    Project = "Aurora Explorer"
  }
}
