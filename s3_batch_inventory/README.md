# `s3_batch_inventory`

This Terraform module is designed to add S3 Inventory configurations to all S3 buckets in a given list, as well as an S3 bucket to store the Inventory CSV files. Optionally, it can also create an S3 access log bucket, if one does not already exist, for the Inventory bucket.

The Inventory filter is configured to include the following fields:

- `LastModifiedDate`
- `ETag`
- `EncryptionStatus`

***Note:*** This was originally designed to retroactively add Inventory configs to older buckets (some created ad hoc as opposed to via Terraform), but can also be used in any case where the list of S3 buckets is static.

## Examples

Using a default region of `us-west-2`, with a log bucket already created:

```hcl
module "s3_inventory_uw2" {
  source = "github.com/18F/identity-terraform//s3_batch_inventory?ref=master"

  log_bucket   = "login-gov.s3-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  bucket_prefix = "login-gov"
  bucket_list   = var.bucket_list_uw2
}
```

Using a provider alias for `us-east-1`, allowing the module to create the log bucket:

```
module "s3_inventory_ue1" {
  source = "github.com/18F/identity-terraform//s3_batch_inventory?ref=master"
  providers = {
    aws = aws.us-east-1
  }

  region = "us-east-1"
  bucket_prefix = "login-gov"
  bucket_list   = var.bucket_list_ue1
}
```

## Variables

`bucket_prefix` - First substring in S3 bucket name of `$bucket_prefix.s3-inventory.$account_id-$region`
`bucket_list` - List of buckets (names only, *not* full ARNs) to have Inventory configurations added to them.
`log_bucket` - Name of the bucket used for S3 logging. If left blank, the module will create one named `$bucket_prefix.s3-inv-logs.$account_id-$region`
`region` - AWS Region
