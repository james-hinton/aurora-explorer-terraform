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

# Attach dynamodb access policy to the role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Attach s3 access policy to the role
resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


# Attach secrets manager access policy to the role
resource "aws_iam_policy" "lambda_secretsmanager_access" {
  name   = "lambda_secretsmanager_access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ],
        Effect   = "Allow",
        Resource = "*"  # TODO: Replace with the ARN of the secret
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secretsmanager_access_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_secretsmanager_access.arn
}

# Attach EKS access policy to the role
resource "aws_iam_policy" "lambda_eks_access" {
  name   = "lambda_eks_access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:DescribeCluster"          
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_eks_access_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_eks_access.arn
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
  source_code_hash = filebase64sha256("${path.module}/../aurora-explorer-lambda-functions/retrieve_data/package.zip")
}

# Lambda function for triggering k8s job
resource "aws_lambda_function" "k8_job_trigger" {
  function_name = "k8_job_trigger"

  s3_bucket        = "aurora-explorer-data"
  s3_key           = "k8-job-trigger.zip"

  handler = "handler.lambda_handler"
  runtime = "python3.10"

  role = aws_iam_role.lambda_execution_role.arn
  timeout = 60

  source_code_hash = filebase64sha256("${path.module}/../aurora-explorer-lambda-functions/k8_job_trigger/k8-job-trigger.zip")

  environment {
    variables = {
      K8S_API_ENDPOINT = module.eks.cluster_endpoint
    }
  }
}


# cloud watch
resource "aws_iam_policy" "lambda_cloudwatch_logs_policy" {
  name   = "lambda_cloudwatch_logs_policy"
  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource: "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_logs_policy.arn
}
