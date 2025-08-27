# `cloudtrail`

This Terraform module creates an AWS CloudTrail resource (i.e. a 'CloudTrail trail') along with basic associated infrastructure for it all to work correctly, including:

- IAM role and policy to allow CloudTrail access to CloudWatch Logs
- S3 bucket that CloudTrail uploads its logs to, with associated config resources (server-side encryption, logging, etc.)
- KMS key used for CloudTrail to encrypt/decrypt events (which can also be used by the S3 bucket), with multi-region/replica support

Notably, the `aws_cloudtrail.main` resource uses a set of `dynamic` blocks to take data from one of two list variables -- `var.basic_event_selectors` or
`var.advanced_event_selectors` -- to define and create Event Selectors for the trail, based on which variable is used and what is put into it. (Variable validation blocks prevent _both_ variables from being used at the same time, since a trail cannot use both Basic AND Advanced Event Selectors!)

# Examples

## CloudTrail Trail with Basic Event Selectors

```hcl
module "cloudtrail_basic" {
  source = "github.com/18F/identity-terraform//cloudtrail?ref=main"

  trail_name = "login-gov-cloudtrail-basic"
  enable_log_file_validation    = true
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true

  basic_event_selectors = [
    {
      include_management_events = true
      read_write_type           = "All"
      data_resources = {
        # log data events for all objects in all S3 buckets
        "AWS::S3::Object" = [
          "arn:aws:s3",
        ],
        # log data events for specific Lambda functions
        "AWS::Lambda::Function" = [
          "arn:aws:lambda:us-east-1:111122223333:function:my-lambda-function-01",
          "arn:aws:lambda:us-east-1:111122223333:function:my-lambda-function-02",
        ]
      }
    }
  ]
}
```

## CloudTrail Trail with Advanced Event Selectors

```hcl
module "cloudtrail_advanced" {
  source = "github.com/18F/identity-terraform//cloudtrail?ref=main"

  trail_name = "login-gov-cloudtrail-advanced"
  enable_log_file_validation    = true
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true

  advanced_event_selectors = [
    {
      name = "Log PutObject and DeleteObject events for all but one bucket"
      category = "Data"
      read_only = true
      resource_type = "AWS::S3::Object"
      fields = {
        "eventName" = {
          equals = ["PutObject","DeleteObject"]
        },
        "resources.ARN" = {
          not_starts_with = ["arn:aws:s3:::amzn-s3-demo-bucket/"]
        },
      }
    },
    {
      name = "Log readOnly and writeOnly management events"
      category = "Management"
    },
  ]
}
```

# Detailed Configuration


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
| <a name="module_cloudtrail_bucket_config"></a> [cloudtrail\_bucket\_config](#module\_cloudtrail\_bucket\_config) | github.com/18F/identity-terraform//s3_config | 188d82b9e9b7423f1a71988413ec5899d31807fe |

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |
| [aws_cloudwatch_log_group.cloudtrail_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.cloudtrail_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cloudtrail_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_alias.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.cloudtrail_replica](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_kms_replica_key.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_replica_key) | resource |
| [aws_s3_bucket.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudtrail_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudtrail_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudtrail_cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudtrail_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_advanced_event_selectors"></a> [advanced\_event\_selectors](#input\_advanced\_event\_selectors) | Map containing data on advanced event selectors to configure for the aws\_cloudtrail.main resource.<br/>CANNOT be used in combination with var.basic\_event\_selectors; only one may be selected.<br/>Refer to commented-out defaults for an example of the structure to use. | <pre>list(object({<br/>    name          = string<br/>    category      = string<br/>    read_only     = optional(bool)<br/>    error_code    = optional(string)<br/>    resource_type = optional(string)<br/>    fields = optional(map(object({<br/>      equals          = optional(list(string))<br/>      not_equals      = optional(list(string))<br/>      ends_with       = optional(list(string))<br/>      not_ends_with   = optional(list(string))<br/>      not_starts_with = optional(list(string))<br/>      starts_with     = optional(list(string))<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_basic_event_selectors"></a> [basic\_event\_selectors](#input\_basic\_event\_selectors) | Map containing data on basic event selectors to configure for the aws\_cloudtrail.main resource.<br/>CANNOT be used in combination with var.advanced\_event\_selectors; only one may be selected.<br/>Refer to commented-out default for an example of the structure to use. | <pre>list(object({<br/>    include_management_events = bool<br/>    read_write_type           = string<br/>    excluded_sources          = optional(list(string))<br/>    data_resources            = map(list(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_cloudwatch_retention_days"></a> [cloudwatch\_retention\_days](#input\_cloudwatch\_retention\_days) | Number of days to retain Streams for all CloudWatch Log Groups defined in/created by this module. | `number` | `365` | no |
| <a name="input_enable_log_file_validation"></a> [enable\_log\_file\_validation](#input\_enable\_log\_file\_validation) | Whether log file integrity validation is enabled for the aws\_cloudtrail.main resource. | `bool` | `true` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Whether or not to enable logging for the aws\_cloudtrail.main resource. | `bool` | `true` | no |
| <a name="input_include_global_service_events"></a> [include\_global\_service\_events](#input\_include\_global\_service\_events) | Whether the aws\_cloudtrail.main resource is publishing events from global services (e.g. IAM) to logs. | `bool` | `false` | no |
| <a name="input_inventory_bucket_arn"></a> [inventory\_bucket\_arn](#input\_inventory\_bucket\_arn) | ARN of the S3 bucket used for collecting the S3 Inventory reports. | `string` | n/a | yes |
| <a name="input_is_multi_region_trail"></a> [is\_multi\_region\_trail](#input\_is\_multi\_region\_trail) | Whether the aws\_cloudtrail.main resource is created in the current region or in all regions. | `bool` | `false` | no |
| <a name="input_is_organization_trail"></a> [is\_organization\_trail](#input\_is\_organization\_trail) | Whether the aws\_cloudtrail.main resource is an AWS Organizations trail.<br/>Can ONLY be created / set to 'true' in the master account for an organization. | `bool` | `false` | no |
| <a name="input_kms_deletion_window"></a> [kms\_deletion\_window](#input\_kms\_deletion\_window) | Waiting period (days) before aws\_kms\_key.cloudtrail is deleted, if ScheduleKeyDeletion is performed. | `number` | `7` | no |
| <a name="input_kms_enable_rotation"></a> [kms\_enable\_rotation](#input\_kms\_enable\_rotation) | Whether or not to enable automatic rotation of the aws\_kms\_key.cloudtrail resource. | `bool` | `true` | no |
| <a name="input_kms_regions"></a> [kms\_regions](#input\_kms\_regions) | List of regions to create replica KMS keys for the aws\_kms\_key.cloudtrail resource. | `list(string)` | `[]` | no |
| <a name="input_kms_rotation_period"></a> [kms\_rotation\_period](#input\_kms\_rotation\_period) | Period of time (days) between key rotations of the aws\_kms\_key.cloudtrail resource. | `number` | `90` | no |
| <a name="input_logging_bucket_id"></a> [logging\_bucket\_id](#input\_logging\_bucket\_id) | Id of the S3 bucket used for collecting the S3 access events | `string` | n/a | yes |
| <a name="input_prevent_tf_log_deletion"></a> [prevent\_tf\_log\_deletion](#input\_prevent\_tf\_log\_deletion) | Whether to ACTUALLY destroy CloudWatch Log Groups in this module vs. just removing them from state when using -destroy. | `bool` | `false` | no |
| <a name="input_s3_bucket_key_enabled"></a> [s3\_bucket\_key\_enabled](#input\_s3\_bucket\_key\_enabled) | Whether or not to use aws\_kms\_key.cloudtrail as the S3 Bucket Key for aws\_s3\_bucket.cloudtrail | `bool` | `false` | no |
| <a name="input_s3_force_destroy"></a> [s3\_force\_destroy](#input\_s3\_force\_destroy) | Allow destruction of aws\_s3\_bucket.cloudtrail bucket even if is not empty. | `bool` | `false` | no |
| <a name="input_s3_sse_algorithm"></a> [s3\_sse\_algorithm](#input\_s3\_sse\_algorithm) | SSE encryption algorithm used with the aws\_s3\_bucket.cloudtrail S3 bucket. | `string` | `"AES256"` | no |
| <a name="input_trail_name"></a> [trail\_name](#input\_trail\_name) | Name of the CloudTrail trail. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of the cloudtrail\_default CloudWatch Log Group |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the cloudtrail\_default CloudWatch Log Group |
| <a name="output_cloudwatch_logs_role_arn"></a> [cloudwatch\_logs\_role\_arn](#output\_cloudwatch\_logs\_role\_arn) | ARN of the cloudtrail\_cloudwatch\_logs IAM role |
| <a name="output_enable_log_file_validation"></a> [enable\_log\_file\_validation](#output\_enable\_log\_file\_validation) | Whether or not enable\_log\_file\_validation is enabled |
| <a name="output_include_global_service_events"></a> [include\_global\_service\_events](#output\_include\_global\_service\_events) | Whether or not include\_global\_service\_events is enabled |
| <a name="output_is_multi_region_trail"></a> [is\_multi\_region\_trail](#output\_is\_multi\_region\_trail) | Whether or not is\_multi\_region\_trail is enabled |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Name of the S3 bucket used by CloudTrail |
| <a name="output_trail_arn"></a> [trail\_arn](#output\_trail\_arn) | ARN of the CloudTrail trail |
| <a name="output_trail_name"></a> [trail\_name](#output\_trail\_name) | Name of the CloudTrail trail |
<!-- END_TF_DOCS -->