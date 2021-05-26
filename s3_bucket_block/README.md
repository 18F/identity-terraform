# `s3_bucket_block`

This Terraform module is designed to create an S3 bucket, or a set of buckets, from a map variable containing various bucket configurations. It provides consistency for the following, in all buckets provided:

- Bucket naming scheme
- Versioning enabled
- Logging enabled
- KMS SSE

A public access block and S3 Inventory configuration is also applied to each bucket in the provided list.

## Dynamic Settings

By default, only the bucket's name is needed within the provided `bucket_data` map variable. This is built from:
- `var.bucket_name_prefix`
- `each.key` (in the `bucket_data` map variable)
- `data.aws_caller_identity.current.account_id`
- `var.region`

The following additional settings can be configured via key-value pairs in the map:
- `acl` (defaults to `private`)
- `policy` (defaults to `""`)
- `force_destroy` (defaults to `true`)
- `lifecycle_rules` (list, defaults to `[]` and does not create any lifecycle rules unless provided)
- `public_access_block` (defaults to `true`; creates an `aws_s3_bucket_public_access_block` resource for the accordant bucket)

## Example

```hcl
module "s3_shared" {
    source = "github.com/18F/identity-terraform//s3_bucket_block?ref=master"
    
    log_bucket         = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
    bucket_name_prefix = "login-gov"
    bucket_data        = {
        "shared-data"      = {
            policy = data.aws_iam_policy_document.shared.json
        },
        "lambda-functions" = {
            policy          = data.aws_iam_policy_document.lambda-functions.json
            lifecycle_rules = [
                {
                    id          = "inactive"
                    enabled     = true
                    prefix      = "/"
                    transitions = [
                        {
                            days          = 180
                            storage_class = "STANDARD_IA"
                        }
                    ]
                }
            ],
            force_destroy = false
        }, 
        "waf-logs" = {},
    }
}
```

## Variables

`bucket_name_prefix` - First substring in S3 bucket name of `$bucket_name_prefix.$bucket_name.$account_id-$region`
`bucket_data` - Map of bucket names and their configuration blocks.
`log_bucket` - Full name of the bucket used for S3 logging.
`region` - AWS Region
`inventory_bucket_arn` - ARN of the S3 bucket used for collecting the S3 Inventory reports.
`optional_fields` - List of optional data fields to collect in S3 Inventory reports. Defaults to the full list of possible fields.

## Outputs

`buckets` - A map of the format `var.bucket_data.each.key` => `aws_s3_bucket.bucket[*]["id"]` allowing one to obtain the full bucket name from the shorter key reference.