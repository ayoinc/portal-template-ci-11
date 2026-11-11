# State in S3. The bucket and its region are passed to `terraform init` with
# -backend-config; see README.md.
terraform {
  backend "s3" {
    key          = "application/aws/sample-billing-resources/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
