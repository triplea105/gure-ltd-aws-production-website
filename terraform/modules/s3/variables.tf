variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "tags" {
  description = "Tags applied to S3 resources"
  type        = map(string)
  default     = {}
}
