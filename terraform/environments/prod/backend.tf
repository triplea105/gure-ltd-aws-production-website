# Remote state requires the CloudFormation bootstrap stack to be deployed first.
terraform {
  backend "s3" {
    bucket       = "gure-ltd-terraform-state-232913809627"
    key          = "prod/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    kms_key_id   = "alias/gure-ltd-terraform-state"
    use_lockfile = true
  }
}
