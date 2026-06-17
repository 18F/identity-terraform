# `s3_bucket`

This module is used to create an AWS S3 bucket along with various configuration resources commonly used with S3 buckets.


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
| [aws_kms_alias.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_inventory.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_inventory) | resource |
| [aws_s3_bucket_lifecycle_configuration.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_require_secure_connections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_block_public_access"></a> [block\_public\_access](#input\_block\_public\_access) | Whether or not to enable the public access block for this bucket. | `bool` | `true` | no |
| <a name="input_bucket_acl"></a> [bucket\_acl](#input\_bucket\_acl) | Type of bucket ACL to use, if any (generally discouraged for newer buckets); leave blank to skip creation.<br/>Valid values: private, public-read, public-read-write, aws-exec-read, authenticated-read,<br/>bucket-owner-read, bucket-owner-full-control, log-delivery-write. | `string` | `""` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket to create | `string` | n/a | yes |
| <a name="input_bucket_policy_doc"></a> [bucket\_policy\_doc](#input\_bucket\_policy\_doc) | An additonal source\_policy\_document (in JSON) to add to the S3 bucket policy, if using one.<br/>Will default to only using the contents of the s3\_secure\_connections policy document if not set. | `string` | `""` | no |
| <a name="input_bucket_tags"></a> [bucket\_tags](#input\_bucket\_tags) | Tags for the S3 bucket. | `map(string)` | `{}` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow destruction of the S3 bucket, even if it contains objects. | `bool` | `true` | no |
| <a name="input_inventory_config"></a> [inventory\_config](#input\_inventory\_config) | Map/object var containing all configuration related to S3 Inventory. Leave/set to {} to disable inventory configuration. | <pre>map(object({<br/>    included_versions = string<br/>    frequency         = string<br/>    filter_prefix     = optional(string)<br/>    format            = string<br/>    bucket_arn        = string<br/>    bucket_account_id = optional(number)<br/>    bucket_sse        = string<br/>    bucket_kms_key_id = optional(string)<br/>    inventory_prefix  = optional(string)<br/>    optional_fields   = optional(list(string))<br/>  }))</pre> | <pre>{<br/>  "FullBucketDailyInventory": {<br/>    "bucket_arn": "",<br/>    "bucket_sse": "sse_s3",<br/>    "format": "Parquet",<br/>    "frequency": "Daily",<br/>    "included_versions": "All",<br/>    "optional_fields": [<br/>      "Size",<br/>      "LastModifiedDate",<br/>      "StorageClass",<br/>      "ETag",<br/>      "IsMultipartUploaded",<br/>      "ReplicationStatus",<br/>      "EncryptionStatus",<br/>      "ObjectLockRetainUntilDate",<br/>      "ObjectLockMode",<br/>      "ObjectLockLegalHoldStatus",<br/>      "IntelligentTieringAccessTier"<br/>    ]<br/>  }<br/>}</pre> | no |
| <a name="input_key_policy_doc"></a> [key\_policy\_doc](#input\_key\_policy\_doc) | An additonal source\_policy\_document (in JSON) to add to the KMS key policy, if using one.<br/>Will default to only using the basic IAMAndRoot statement if not set. | `string` | `""` | no |
| <a name="input_lifecycle_minimum_object_size"></a> [lifecycle\_minimum\_object\_size](#input\_lifecycle\_minimum\_object\_size) | The default minimum object size behavior applied to the lifecycle configuration, if var.lifecycle\_rules is defined.<br/>Valid values: varies\_by\_storage\_class, all\_storage\_classes\_128K | `string` | `"varies_by_storage_class"` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | Detailed map of lifecycle configuration rules. Each must have a 'status', and one or more types of transition/expiration<br/>blocks. Leave empty (i.e. '{}') to skip creating the aws\_s3\_bucket\_lifecycle\_configuration resource entirely. | <pre>map(object({<br/>    status                      = string<br/>    filter_prefix               = optional(string, "/")<br/>    abort_days_after_initiation = optional(number)<br/>    transition = optional(map({<br/>      date          = optional(string)<br/>      days          = optional(number)<br/>      storage_class = string<br/>    }))<br/>    expiration = optional(map({<br/>      date                         = optional(string)<br/>      days                         = optional(number)<br/>      expired_object_delete_marker = optional(bool)<br/>    }))<br/>    noncurrent_version_expiration = optional(map({<br/>      newer_noncurrent_versions = optional(number)<br/>      noncurrent_days           = number<br/>    }))<br/>    noncurrent_version_transition = optional(map({<br/>      newer_noncurrent_versions = optional(number)<br/>      noncurrent_days           = number<br/>      storage_class             = string<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_logging_bucket_id"></a> [logging\_bucket\_id](#input\_logging\_bucket\_id) | S3 bucket used for logging S3 access events. CANNOT be the same bucket targeted by this module! | `string` | `""` | no |
| <a name="input_object_ownership"></a> [object\_ownership](#input\_object\_ownership) | Object Ownership. Valid values: BucketOwnerPreferred, ObjectWriter or BucketOwnerEnforced | `string` | `"BucketOwnerPreferred"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region for the module. | `string` | `"us-west-2"` | no |
| <a name="input_sse_config"></a> [sse\_config](#input\_sse\_config) | Object var containing all configuration related to S3 server-side encryption. | <pre>object({<br/>    algorithm                = string<br/>    create_kms_key           = bool<br/>    kms_key_rotation         = optional(number)<br/>    custom_kms_alias         = optional(string)<br/>    bucket_key_enabled       = bool<br/>    blocked_encryption_types = list(string)<br/>  })</pre> | <pre>{<br/>  "algorithm": "AES256",<br/>  "blocked_encryption_types": [<br/>    "SSE-C"<br/>  ],<br/>  "bucket_key_enabled": false,<br/>  "create_kms_key": false<br/>}</pre> | no |
| <a name="input_versioning_status"></a> [versioning\_status](#input\_versioning\_status) | Status of Bucket Versioning. Valid values are 'Enabled' or 'Suspended'; 'Disabled' cannot be used. | `string` | `"Enabled"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 bucket. |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | ID (name) of the S3 bucket. |
| <a name="output_kms"></a> [kms](#output\_kms) | ARN of the KMS key used with the S3 bucket; generated if var.sse\_config.create\_kms\_key = true. |
<!-- END_TF_DOCS -->