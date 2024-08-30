# `s3_config`

This module is used to add a public access block, S3 Inventory configuration, and access logging to the provided bucket name. It can be configured to use either:

- a templated bucket name, using the `PREFIX.NAME.ACCOUNTID-REGION` schema, or
- a manually-set bucket name, using the `bucket_name_override` variable

To work properly:

- An S3 bucket for collecting Inventory reports must already exist; its ARN is required for the `inventory_bucket_arn` variable.
- An S3 bucket for access logging must already exist; its ID is required for the `logging_bucket_id` variable.

## Example

```hcl
module "secrets_bucket_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=main"

  bucket_name_prefix   = var.bucket_name_prefix
  bucket_name          = var.secrets_bucket_type
  region               = var.region
  inventory_bucket_arn = local.inventory_bucket_arn
  logging_bucket_id    = data.aws_s3_bucket.access_logging_bucket.id
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket_inventory.daily](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_inventory) | resource |
| [aws_s3_bucket_logging.access_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_public_access_block.public_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_inventory_bucket_arn"></a> [inventory\_bucket\_arn](#input\_inventory\_bucket\_arn) | ARN of the S3 bucket used for collecting the S3 Inventory reports. | `string` | n/a | yes |
| <a name="input_logging_bucket_id"></a> [logging\_bucket\_id](#input\_logging\_bucket\_id) | ID of the S3 bucket used for collecting the S3 access events | `string` | n/a | yes |
| <a name="input_block_public_access"></a> [block\_public\_access](#input\_block\_public\_access) | Whether or not to enable the public access block for this bucket. | `bool` | `true` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Main/second substring in S3 bucket name of $bucket\_name\_prefix.$bucket\_name.$account\_id-$region | `string` | `""` | no |
| <a name="input_bucket_name_override"></a> [bucket\_name\_override](#input\_bucket\_name\_override) | Set this to override the normal bucket naming schema. | `string` | `""` | no |
| <a name="input_bucket_name_prefix"></a> [bucket\_name\_prefix](#input\_bucket\_name\_prefix) | First substring in S3 bucket name of $bucket\_name\_prefix.$bucket\_name.$account\_id-$region | `string` | `""` | no |
| <a name="input_optional_fields"></a> [optional\_fields](#input\_optional\_fields) | List of optional data fields to collect in S3 Inventory reports. | `list(string)` | <pre>[<br>  "Size",<br>  "LastModifiedDate",<br>  "StorageClass",<br>  "ETag",<br>  "IsMultipartUploaded",<br>  "ReplicationStatus",<br>  "EncryptionStatus",<br>  "ObjectLockRetainUntilDate",<br>  "ObjectLockMode",<br>  "ObjectLockLegalHoldStatus",<br>  "IntelligentTieringAccessTier"<br>]</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | `"us-west-2"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
