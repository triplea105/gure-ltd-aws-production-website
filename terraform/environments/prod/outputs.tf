output "website_bucket_name" {
  description = "Name of the private S3 bucket that stores website assets"
  value       = module.website_bucket.bucket_name
}

output "website_bucket_arn" {
  description = "ARN of the private S3 bucket that stores website assets"
  value       = module.website_bucket.bucket_arn
}

output "website_bucket_regional_domain_name" {
  description = "Regional domain name used later by CloudFront"
  value       = module.website_bucket.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for the website"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name for the website"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "route53_name_servers" {
  description = "Route 53 name servers that must be configured at the domain registrar"
  value       = var.enable_custom_domain ? aws_route53_zone.primary[0].name_servers : []
}

output "website_certificate_arn" {
  description = "ACM certificate used by CloudFront for the custom domain"
  value       = var.enable_custom_domain ? aws_acm_certificate.website[0].arn : null
}

output "api_endpoint" {
  description = "HTTP API endpoint for active website requests"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "requests_table_name" {
  description = "DynamoDB table storing customer requests"
  value       = aws_dynamodb_table.requests.name
}

output "services_table_name" {
  description = "DynamoDB table storing service availability"
  value       = aws_dynamodb_table.services.name
}

output "alerts_topic_arn" {
  description = "SNS topic ARN for operational alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch operations dashboard"
  value       = aws_cloudwatch_dashboard.application.dashboard_name
}
