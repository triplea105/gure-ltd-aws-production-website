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
    detailed_metrics_enabled = true
    throttling_burst_limit   = 50
    throttling_rate_limit    = 100
  }

  route_settings {
    route_key                = "POST /requests"
    detailed_metrics_enabled = true
    throttling_burst_limit   = 10
    throttling_rate_limit    = 5
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

