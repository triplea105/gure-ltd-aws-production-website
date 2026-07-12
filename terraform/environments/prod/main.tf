locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  website_dir  = "${path.root}/../../../website"
  lambda_names = toset(["health", "services", "requests"])

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  content_types = {
    css  = "text/css"
    html = "text/html"
    js   = "application/javascript"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    png  = "image/png"
    svg  = "image/svg+xml"
    webp = "image/webp"
  }

  seed_services = {
    fuel-delivery = {
      service_id   = "fuel-delivery"
      category     = "logistics"
      name         = "Fuel Delivery"
      description  = "Fuel transport and delivery coordination for commercial needs."
      availability = "available"
      request_type = "logistics_request"
    }
    cooking-oil-delivery = {
      service_id   = "cooking-oil-delivery"
      category     = "logistics"
      name         = "Cooking Oil Delivery"
      description  = "Delivery support for cooking oil supply and distribution."
      availability = "available"
      request_type = "logistics_request"
    }
    container-transport = {
      service_id   = "container-transport"
      category     = "logistics"
      name         = "Container Transport"
      description  = "Container movement for commercial and logistics operations."
      availability = "available"
      request_type = "logistics_request"
    }
    excavator-hire = {
      service_id   = "excavator-hire"
      category     = "vehicle_hire"
      name         = "Excavator"
      description  = "Heavy machinery for digging, trenching, and earthmoving."
      availability = "available"
      request_type = "vehicle_hire_request"
    }
    wheel-loader-hire = {
      service_id   = "wheel-loader-hire"
      category     = "vehicle_hire"
      name         = "Wheel Loader"
      description  = "Vehicle hire for loading, moving, and site material handling."
      availability = "available"
      request_type = "vehicle_hire_request"
    }
    roller-hire = {
      service_id   = "roller-hire"
      category     = "vehicle_hire"
      name         = "Roller"
      description  = "Compaction equipment for road and paving work."
      availability = "unavailable"
      request_type = "vehicle_hire_request"
    }
    road-paving-blocks = {
      service_id   = "road-paving-blocks"
      category     = "hardware_materials"
      name         = "Road Paving Blocks"
      description  = "Interlocking paving blocks for roads, yards, and construction projects."
      availability = "in_stock"
      request_type = "hardware_material_request"
    }
    construction-tools = {
      service_id   = "construction-tools"
      category     = "hardware_materials"
      name         = "Construction Tools"
      description  = "Tool and hardware requests for construction work."
      availability = "available"
      request_type = "hardware_material_request"
    }
    building-materials = {
      service_id   = "building-materials"
      category     = "hardware_materials"
      name         = "Building Materials"
      description  = "Material requests coordinated based on customer project needs."
      availability = "available_on_request"
      request_type = "hardware_material_request"
    }
  }
}

module "website_bucket" {
  source = "../../modules/s3"

  bucket_name = var.website_bucket_name
  tags        = local.common_tags
}

resource "aws_s3_object" "website_files" {
  for_each = setsubtract(
    fileset(local.website_dir, "**/*"),
    toset(concat(["assets/images/.gitkeep"], var.generate_deployed_api_config ? ["assets/js/config.js"] : []))
  )

  bucket       = module.website_bucket.bucket_name
  key          = each.value
  source       = "${local.website_dir}/${each.value}"
  etag         = filemd5("${local.website_dir}/${each.value}")
  content_type = lookup(local.content_types, lower(element(reverse(split(".", each.value)), 0)), "application/octet-stream")
}

resource "aws_dynamodb_table" "requests" {
  name         = "${local.name_prefix}-requests"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "request_id"

  attribute {
    name = "request_id"
    type = "S"
  }

  attribute {
    name = "request_type"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  global_secondary_index {
    name            = "request_type-created_at-index"
    hash_key        = "request_type"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "status-created_at-index"
    hash_key        = "status"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.common_tags
}

resource "aws_dynamodb_table" "services" {
  name         = "${local.name_prefix}-services"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "service_id"

  attribute {
    name = "service_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.common_tags
}

resource "aws_dynamodb_table_item" "seed_services" {
  for_each = local.seed_services

  table_name = aws_dynamodb_table.services.name
  hash_key   = aws_dynamodb_table.services.hash_key

  item = jsonencode({
    service_id = {
      S = each.value.service_id
    }
    category = {
      S = each.value.category
    }
    name = {
      S = each.value.name
    }
    description = {
      S = each.value.description
    }
    availability = {
      S = each.value.availability
    }
    request_type = {
      S = each.value.request_type
    }
  })
}

resource "aws_sesv2_email_identity" "business_sender" {
  count = var.enable_request_notifications ? 1 : 0

  email_identity = var.ses_source_email

  tags = local.common_tags
}

resource "aws_route53_zone" "primary" {
  count = var.enable_custom_domain ? 1 : 0

  name = var.domain_name

  tags = local.common_tags
}

resource "aws_acm_certificate" "website" {
  count    = var.enable_custom_domain ? 1 : 0
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

resource "aws_route53_record" "certificate_validation" {
  for_each = var.enable_custom_domain ? {
    for option in aws_acm_certificate.website[0].domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  } : {}

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "website" {
  count    = var.enable_custom_domain_validation ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.website[0].arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}

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

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda_logs,
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

  environment {
    variables = {
      SERVICES_TABLE_NAME = aws_dynamodb_table.services.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda_logs,
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
    aws_iam_role_policy.requests_data,
  ]

  tags = local.common_tags
}

resource "aws_apigatewayv2_api" "this" {
  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["content-type"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = distinct(concat(var.allowed_origins, ["https://${aws_cloudfront_distribution.website.domain_name}"]))
    max_age       = 3600
  }

  tags = local.common_tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 100
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      responseLength   = "$context.responseLength"
      responseLatency  = "$context.responseLatency"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "health" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.health.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "services" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.services.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "requests" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.requests.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.health.id}"
}

resource "aws_apigatewayv2_route" "services" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /services"
  target    = "integrations/${aws_apigatewayv2_integration.services.id}"
}

resource "aws_apigatewayv2_route" "services_by_category" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /services/{category}"
  target    = "integrations/${aws_apigatewayv2_integration.services.id}"
}

resource "aws_apigatewayv2_route" "requests" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /requests"
  target    = "integrations/${aws_apigatewayv2_integration.requests.id}"
}

resource "aws_lambda_permission" "health_api" {
  statement_id  = "AllowApiGatewayHealth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/GET/health"
}

resource "aws_lambda_permission" "services_api" {
  statement_id  = "AllowApiGatewayServices"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.services.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/GET/services*"
}

resource "aws_lambda_permission" "requests_api" {
  statement_id  = "AllowApiGatewayRequests"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.requests.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/POST/requests"
}

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${local.name_prefix}-website-oac"
  description                       = "Allows CloudFront to access the private website bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  web_acl_id          = aws_wafv2_web_acl.cloudfront.arn
  aliases             = var.enable_custom_domain_alias ? [var.domain_name, "www.${var.domain_name}"] : []

  origin {
    domain_name              = module.website_bucket.bucket_regional_domain_name
    origin_id                = "website-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  default_cache_behavior {
    target_origin_id       = "website-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.enable_custom_domain_alias ? aws_acm_certificate.website[0].arn : null
    cloudfront_default_certificate = var.enable_custom_domain_alias ? null : true
    minimum_protocol_version       = var.enable_custom_domain_alias ? "TLSv1.2_2021" : null
    ssl_support_method             = var.enable_custom_domain_alias ? "sni-only" : null
  }

  tags = local.common_tags
}

data "aws_iam_policy_document" "website_bucket" {
  statement {
    sid     = "AllowCloudFrontRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = [
      "${module.website_bucket.bucket_arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = module.website_bucket.bucket_name
  policy = data.aws_iam_policy_document.website_bucket.json
}

resource "aws_route53_record" "website_ipv4" {
  for_each = var.enable_custom_domain_alias ? toset([var.domain_name, "www.${var.domain_name}"]) : toset([])

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website_ipv6" {
  for_each = var.enable_custom_domain_alias ? toset([var.domain_name, "www.${var.domain_name}"]) : toset([])

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = each.value
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_wafv2_web_acl" "cloudfront" {
  provider = aws.us_east_1

  name        = "${local.name_prefix}-cloudfront-waf"
  description = "Basic managed WAF protection for the website"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitPerIp"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = var.waf_rate_limit
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-cloudfront-waf"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}

resource "aws_s3_object" "api_config" {
  count = var.generate_deployed_api_config ? 1 : 0

  bucket       = module.website_bucket.bucket_name
  key          = "assets/js/config.js"
  content      = "window.GURE_API_BASE_URL = \"${aws_apigatewayv2_api.this.api_endpoint}\";\n"
  content_type = "application/javascript"
  etag         = md5("window.GURE_API_BASE_URL = \"${aws_apigatewayv2_api.this.api_endpoint}\";\n")
}

resource "aws_sns_topic" "alerts" {
  name              = "${local.name_prefix}-alerts"
  kms_master_key_id = "alias/aws/sns"
  tags              = local.common_tags
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_log_metric_filter" "ses_notification_failures" {
  name           = "${local.name_prefix}-ses-notification-failures"
  pattern        = "ses_notification_failed"
  log_group_name = aws_cloudwatch_log_group.lambda["requests"].name

  metric_transformation {
    name      = "SesNotificationFailures"
    namespace = "GureLtd/Notifications"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = {
    health   = aws_lambda_function.health.function_name
    services = aws_lambda_function.services.function_name
    requests = aws_lambda_function.requests.function_name
  }

  alarm_name          = "${local.name_prefix}-${each.key}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = each.value
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each = {
    health   = aws_lambda_function.health.function_name
    services = aws_lambda_function.services.function_name
    requests = aws_lambda_function.requests.function_name
  }

  alarm_name          = "${local.name_prefix}-${each.key}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = each.value
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "${local.name_prefix}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiId = aws_apigatewayv2_api.this.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${local.name_prefix}-api-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 2000
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiId = aws_apigatewayv2_api.this.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  for_each = {
    requests = aws_dynamodb_table.requests.name
    services = aws_dynamodb_table.services.name
  }

  alarm_name          = "${local.name_prefix}-${each.key}-dynamodb-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TableName = each.value
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_system_errors" {
  for_each = {
    requests = aws_dynamodb_table.requests.name
    services = aws_dynamodb_table.services.name
  }

  alarm_name          = "${local.name_prefix}-${each.key}-dynamodb-system-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "SystemErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TableName = each.value
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ses_notification_failures" {
  alarm_name          = "${local.name_prefix}-ses-notification-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "SesNotificationFailures"
  namespace           = "GureLtd/Notifications"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_dashboard" "application" {
  dashboard_name = "${local.name_prefix}-operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda errors and throttles"
          view   = "timeSeries"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.health.function_name],
            [".", "Throttles", ".", "."],
            [".", "Errors", ".", aws_lambda_function.services.function_name],
            [".", "Throttles", ".", "."],
            [".", "Errors", ".", aws_lambda_function.requests.function_name],
            [".", "Throttles", ".", "."],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "API errors and latency"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          metrics = [
            ["AWS/ApiGateway", "5xx", "ApiId", aws_apigatewayv2_api.this.id, { stat = "Sum" }],
            [".", "4xx", ".", ".", { stat = "Sum" }],
            [".", "Latency", ".", ".", { stat = "Average", yAxis = "right" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "DynamoDB throttles and system errors"
          view   = "timeSeries"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/DynamoDB", "ThrottledRequests", "TableName", aws_dynamodb_table.requests.name],
            [".", "SystemErrors", ".", "."],
            [".", "ThrottledRequests", ".", aws_dynamodb_table.services.name],
            [".", "SystemErrors", ".", "."],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "SES notification failures"
          view   = "timeSeries"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          metrics = [
            ["GureLtd/Notifications", "SesNotificationFailures"],
          ]
        }
      },
    ]
  })
}
