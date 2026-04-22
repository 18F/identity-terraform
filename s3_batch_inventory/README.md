# `s3_batch_inventory`

This Terraform module is designed to add S3 Inventory configurations to all S3 buckets in a given list. The Inventory filter is configured to include the following fields:

- `LastModifiedDate`
- `ETag`
- `EncryptionStatus`

***Note:*** This was originally designed to retroactively add Inventory configs to older buckets (some created ad hoc as opposed to via Terraform), but can also be used in any case where the list of S3 buckets is static.

## Example

```hcl
module "s3_inventory_uw2" {
  source = "github.com/18F/identity-terraform//s3_batch_inventory?ref=main"

  log_bucket   = "login-gov.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  bucket_prefix = "login-gov"
  bucket_list   = var.bucket_list_uw2
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.5 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket_inventory.daily](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_inventory) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_list"></a> [bucket\_list](#input\_bucket\_list) | List of bucket names to have inventory configurations added to them. | `list(string)` | `[]` | no |
| <a name="input_inventory_bucket_arn"></a> [inventory\_bucket\_arn](#input\_inventory\_bucket\_arn) | ARN of the S3 bucket used for collecting the S3 Inventory reports. | `string` | n/a | yes |
| <a name="input_inventory_bucket_kms_key_id"></a> [inventory\_bucket\_kms\_key\_id](#input\_inventory\_bucket\_kms\_key\_id) | KMS key used by the S3 Inventory bucket if var.inventory\_bucket\_sse = 'sse\_kms' | `string` | `""` | no |
| <a name="input_inventory_bucket_sse"></a> [inventory\_bucket\_sse](#input\_inventory\_bucket\_sse) | SSE algorithm used by the S3 Inventory bucket specified by var.inventory\_bucket\_arn | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->