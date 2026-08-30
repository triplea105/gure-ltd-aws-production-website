# Terraform Backend Bootstrap

This directory contains the CloudFormation template used to create Terraform remote state resources.

It creates:

- S3 bucket for Terraform state
- Customer managed KMS key with automatic rotation for state encryption
- S3 lockfile permissions for Terraform state locking
- S3 versioning and encryption
- S3 public access blocking
- Bucket policy that denies insecure transport

Deploy this stack only when you are ready to initialize Terraform with the remote S3 backend.

Existing installations migrating from DynamoDB locking should update this stack, run `terraform init -reconfigure`, and confirm S3 lockfile operation before manually deleting the retained legacy lock table.

After adding or changing the state KMS key, update this stack before running Terraform so the GitHub deployment role can decrypt and update the state and lockfile.
