# ELB Access Logs Bucket

Use this module to create an s3 bucket for storing ELB access logs.  Given a prefix,
will properly namespace the bucket by region and account id and return the full
name to the caller.

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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3_config"></a> [s3\_config](#module\_s3\_config) | github.com/18F/identity-terraform//s3_config | c1ccb75a70894f3c74beed564c0505415d1d1353 |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name_prefix"></a> [bucket\_name\_prefix](#input\_bucket\_name\_prefix) | Base name for the secrets bucket to create | `any` | n/a | yes |
| <a name="input_inventory_bucket_arn"></a> [inventory\_bucket\_arn](#input\_inventory\_bucket\_arn) | ARN of the S3 bucket used for collecting the S3 Inventory reports. | `string` | n/a | yes |
| <a name="input_logging_bucket_id"></a> [logging\_bucket\_id](#input\_logging\_bucket\_id) | Id of the S3 bucket used for collecting the S3 access events | `string` | n/a | yes |
| <a name="input_elb_account_ids"></a> [elb\_account\_ids](#input\_elb\_account\_ids) | Mapping of region to ELB account ID | `map(string)` | <pre>{<br>  "ap-northeast-1": "582318560864",<br>  "ap-northeast-2": "600734575887",<br>  "ap-south-1": "718504428378",<br>  "ap-southeast-1": "114774131450",<br>  "ap-southeast-2": "783225319266",<br>  "ca-central-1": "985666609251",<br>  "cn-north-1": "638102146993",<br>  "eu-central-1": "054676820928",<br>  "eu-west-1": "156460612806",<br>  "eu-west-2": "652711504416",<br>  "sa-east-1": "507241528517",<br>  "us-east-1": "127311923021",<br>  "us-east-2": "033677994240",<br>  "us-gov-west-1": "048591011584",<br>  "us-west-1": "027434742980",<br>  "us-west-2": "797873946194"<br>}</pre> | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Allow destroy even if bucket contains objects | `bool` | `false` | no |
| <a name="input_lifecycle_days_expire"></a> [lifecycle\_days\_expire](#input\_lifecycle\_days\_expire) | Number of days after object creation to delete logs. Set to 0 to disable. | `number` | `0` | no |
| <a name="input_lifecycle_days_glacier"></a> [lifecycle\_days\_glacier](#input\_lifecycle\_days\_glacier) | Number of days after object creation to move logs to Glacier. Set to 0 to disable. | `number` | `365` | no |
| <a name="input_lifecycle_days_standard_ia"></a> [lifecycle\_days\_standard\_ia](#input\_lifecycle\_days\_standard\_ia) | Number of days after object creation to move logs to Standard Infrequent Access. Set to 0 to disable. | `number` | `60` | no |
| <a name="input_log_prefix"></a> [log\_prefix](#input\_log\_prefix) | Prefix inside the bucket where access logs will go | `string` | `"logs"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to create the secrets bucket in | `string` | `"us-west-2"` | no |
| <a name="input_use_prefix_for_permissions"></a> [use\_prefix\_for\_permissions](#input\_use\_prefix\_for\_permissions) | Scope load balancer permissions by log\_prefix | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the s3 logs bucket that was created |
<!-- END_TF_DOCS -->