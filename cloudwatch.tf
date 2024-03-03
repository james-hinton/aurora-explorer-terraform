resource "aws_iam_policy" "cloudwatch_to_step_function_policy" {
  name   = "cloudwatch_to_step_function_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "states:StartExecution",
        Resource = aws_sfn_state_machine.aurora_workflow.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_to_step_function_attachment" {
  role       = aws_iam_role.step_functions_role.id
  policy_arn = aws_iam_policy.cloudwatch_to_step_function_policy.arn
}

resource "aws_cloudwatch_event_rule" "aurora_workflow_trigger" {
  name                = "aurora-workflow-trigger"
  description         = "Triggers the Aurora Workflow state machine every 30 minutes"
  schedule_expression = "rate(30 minutes)"
}

resource "aws_cloudwatch_event_target" "aurora_workflow_target" {
  rule      = aws_cloudwatch_event_rule.aurora_workflow_trigger.name
  arn       = aws_sfn_state_machine.aurora_workflow.arn
  role_arn  = aws_iam_role.step_functions_role.arn

  input_transformer {
    input_paths = {}
    input_template = "\"{}\""
  }
}
