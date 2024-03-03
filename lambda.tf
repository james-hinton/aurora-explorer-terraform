resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Attach necessary policies to the role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Lambda function for retrieving data
resource "aws_lambda_function" "retrieve_data" {
  function_name = "retrieve_data"

  s3_bucket        = "aurora-explorer-data"
  s3_key           = "package.zip"

  handler = "handler.lambda_handler"
  runtime = "python3.10"

  role = aws_iam_role.lambda_execution_role.arn
  timeout = 60
  
  # Important note that this assumes the package.zip file is located there.
  source_code_hash = filebase64sha256("${path.module}/../aurora-explorer-lambda-functions/package.zip")
}