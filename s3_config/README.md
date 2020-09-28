# `s3_config`

This module is used to add a public access block and S3 Inventory configuration to the provided bucket name. It can be configured to use either:

- a templatized bucket name, using the `PREFIX.NAME.ACCOUNTID-REGION` schema, or
- a manually-set bucket name, using the `bucket_name_override` variable

To work properly, an S3 bucket for collecting Inventory reports must already exist; its ARN is required for the `inventory_bucket_arn` variable.

## Example

```hcl
module "secrets_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=master"

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = var.secrets_bucket_type
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
}
```

## Variables

`bucket_name_prefix` - First substring in S3 bucket name of `$bucket_name_prefix.$bucket_name.$account_id-$region`
`bucket_name` - Main/second substring in S3 bucket name of `$bucket_name_prefix.$bucket_name.$account_id-$region`
`bucket_name_override` - Set this to override the normal bucket naming schema. If left blank, `bucket_name_prefix` and `bucket_name` *must* be set.
`region` - AWS Region
`inventory_bucket_arn` - ARN of the S3 bucket used for collecting the S3 Inventory reports.
`optional_fields` - List of optional data fields to collect in S3 Inventory reports. Defaults to the full list of possible fields.
