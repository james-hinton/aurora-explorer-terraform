resource "aws_iam_role" "step_functions_role" {
  name = "step_functions_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy" "step_functions_policy" {
  role   = aws_iam_role.step_functions_role.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_sfn_state_machine" "aurora_workflow" {
  name     = "AuroraWorkflow"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = <<EOF
{
  "Comment": "A workflow to process Aurora data",
  "StartAt": "FetchAuroraData",
  "States": {
    "FetchAuroraData": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.retrieve_data.arn}",
      "End": true
    }
  }
}
EOF
}
