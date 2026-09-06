data "archive_file" "backend" {
  type        = "zip"
  source_dir  = "${path.root}/../../.."
  output_path = "${path.root}/lambda-backend.zip"

  excludes = [
    ".git/**",
    ".github/**",
    ".terraform/**",
    "**/__pycache__/**",
    "**/*.pyc",
    "terraform/**",
    "tests/**",
    "website/**",
  ]
}

resource "aws_iam_role" "lambda_execution" {
  for_each = local.lambda_names

  name = "${local.name_prefix}-${each.key}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = local.lambda_names

  name              = "/aws/lambda/${local.name_prefix}-${each.key}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_iam_role_policy" "lambda_logs" {
  for_each = local.lambda_names

  name = "${local.name_prefix}-${each.key}-lambda-logs"
  role = aws_iam_role.lambda_execution[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda[each.key].arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_tracing" {
  for_each = local.lambda_names

  name = "${local.name_prefix}-${each.key}-lambda-tracing"
  role = aws_iam_role.lambda_execution[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "services_data" {
  name = "${local.name_prefix}-services-data"
  role = aws_iam_role.lambda_execution["services"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Scan"]
        Resource = aws_dynamodb_table.services.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "requests_data" {
  name = "${local.name_prefix}-requests-data"
  role = aws_iam_role.lambda_execution["requests"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.requests.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "requests_email" {
  count = var.enable_request_notifications ? 1 : 0

  name = "${local.name_prefix}-requests-email"
  role = aws_iam_role.lambda_execution["requests"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail"]
        Resource = aws_sesv2_email_identity.business_sender[0].arn
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/aws/apigateway/${local.name_prefix}-api"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_lambda_function" "health" {
  function_name    = "${local.name_prefix}-health"
  role             = aws_iam_role.lambda_execution["health"].arn
  runtime          = var.lambda_runtime
  handler          = "backend.handlers.health.handler"
  filename         = data.archive_file.backend.output_path
  source_code_hash = data.archive_file.backend.output_base64sha256
  timeout          = 10

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda_logs,
    aws_iam_role_policy.lambda_tracing,
  ]

  tags = local.common_tags
}

resource "aws_lambda_function" "services" {
  function_name    = "${local.name_prefix}-services"
  role             = aws_iam_role.lambda_execution["services"].arn
  runtime          = var.lambda_runtime
  handler          = "backend.handlers.services.handler"
  filename         = data.archive_file.backend.output_path
  source_code_hash = data.archive_file.backend.output_base64sha256
  timeout          = 10

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      SERVICES_TABLE_NAME = aws_dynamodb_table.services.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda_logs,
    aws_iam_role_policy.lambda_tracing,
    aws_iam_role_policy.services_data,
  ]

  tags = local.common_tags
}

resource "aws_lambda_function" "requests" {
  function_name    = "${local.name_prefix}-requests"
  role             = aws_iam_role.lambda_execution["requests"].arn
  runtime          = var.lambda_runtime
  handler          = "backend.handlers.requests.handler"
  filename         = data.archive_file.backend.output_path
  source_code_hash = data.archive_file.backend.output_base64sha256
  timeout          = 15
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = merge({
      REQUESTS_TABLE_NAME = aws_dynamodb_table.requests.name
      }, var.enable_request_notifications ? {
      SES_SOURCE_EMAIL      = var.ses_source_email
      SES_DESTINATION_EMAIL = var.ses_destination_email
    } : {})
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda_logs,
    aws_iam_role_policy.lambda_tracing,
    aws_iam_role_policy.requests_data,
  ]

  tags = local.common_tags
}
