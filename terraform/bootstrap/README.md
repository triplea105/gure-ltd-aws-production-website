# Terraform Backend Bootstrap

This directory contains the CloudFormation template used to create Terraform remote state resources.

It creates:

- S3 bucket for Terraform state
- DynamoDB table for Terraform state locking
- S3 versioning and encryption
- S3 public access blocking
- Bucket policy that denies insecure transport

Deploy this stack only when you are ready to initialize Terraform with the remote S3 backend.
