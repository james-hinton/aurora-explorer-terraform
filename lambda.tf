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

# Lambda function for Aurora Explorer status
resource "aws_lambda_function" "status_lambda" {
  function_name = "status"
  filename         = "${path.module}/../aurora-explorer-lambda-functions/status.zip"
  source_code_hash = filebase64sha256("${path.module}/../aurora-explorer-lambda-functions/status.zip")

  handler = "status.lambda_handler"
  runtime = "python3.8"

  role = aws_iam_role.lambda_execution_role.arn
}
