# Remote state requires the CloudFormation bootstrap stack to be deployed first.
terraform {
  backend "s3" {
    bucket         = "gure-ltd-terraform-state-232913809627"
    key            = "prod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "gure-ltd-terraform-locks"
    encrypt        = true
  }
}
