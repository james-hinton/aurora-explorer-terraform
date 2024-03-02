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

# Lambda function for processing data
resource "aws_lambda_function" "process_data_lambda" {
  function_name = "process_data"

  s3_bucket        = "aurora-explorer-data"
  s3_key           = "package.zip"


  handler = "handler.lambda_handler"
  runtime = "python3.10"

  role = aws_iam_role.lambda_execution_role.arn
  
  # Important note that this assumes the package.zip file is located there.
  source_code_hash = filebase64sha256("${path.module}/../aurora-explorer-lambda-functions/package.zip")

  # Credit to lambgeo/lambda-gdal for the layer
  layers = ["arn:aws:lambda:eu-west-2:524387336408:layer:gdal38:1"]

  environment {
    variables = {
      GDAL_DATA = "/opt/share/gdal"
      PROJ_LIB  = "/opt/share/proj"
    }
  }
}