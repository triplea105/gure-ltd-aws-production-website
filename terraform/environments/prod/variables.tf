variable "aws_region" {
  description = "AWS region for production resources"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "gure-ltd"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Optional future custom domain name for the production website; leave empty while using the CloudFront URL"
  type        = string
  default     = ""
}

variable "enable_custom_domain" {
  description = "Whether to create Route 53 hosted zone, ACM certificate request, and DNS validation records"
  type        = bool
  default     = false
}

variable "enable_custom_domain_validation" {
  description = "Whether Terraform should wait for ACM DNS certificate validation"
  type        = bool
  default     = false
}

variable "enable_custom_domain_alias" {
  description = "Whether to attach the custom domain and Route 53 alias records to CloudFront"
  type        = bool
  default     = false
}

variable "generate_deployed_api_config" {
  description = "Whether Terraform should replace the static frontend API config with the deployed API Gateway endpoint"
  type        = bool
  default     = true
}

variable "enable_request_notifications" {
  description = "Whether the requests Lambda should send SES email notifications"
  type        = bool
  default     = true
}

variable "website_bucket_name" {
  description = "S3 bucket name for private frontend website assets"
  type        = string
  default     = "gure-ltd-prod-website-232913809627"
}

variable "allowed_origins" {
  description = "Additional allowed production website origins for API CORS"
  type        = list(string)
  default     = []
}

variable "ses_source_email" {
  description = "Verified SES sender email address"
  type        = string
  default     = "a4hmed11@gmail.com"
}

variable "ses_destination_email" {
  description = "Business email address that receives request notifications"
  type        = string
  default     = "a4hmed11@gmail.com"
}

variable "alert_email" {
  description = "Email address that receives operational SNS alerts"
  type        = string
  default     = "a4hmed11@gmail.com"
}

variable "lambda_runtime" {
  description = "Python runtime used by Lambda functions"
  type        = string
  default     = "python3.12"
}

variable "log_retention_days" {
  description = "Number of days to retain application and API logs"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a retention period supported by CloudWatch Logs."
  }
}

variable "waf_rate_limit" {
  description = "Maximum requests allowed from one IP during a five-minute WAF evaluation window"
  type        = number
  default     = 1000

  validation {
    condition     = var.waf_rate_limit >= 100
    error_message = "waf_rate_limit must be at least 100 requests per five minutes."
  }
}
