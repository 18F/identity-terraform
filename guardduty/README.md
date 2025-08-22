# `guardduty`

This module creates and manages a GuardDuty Detector for an AWS account (in a single region), along with associated resources:

- Enablement of GuardDuty 'Features' (formerly 'datasources') for each item in `var.enabled_features`
- S3 bucket used as a GuardDuty Publishing Destination + config resources (lifecycle/policy/logging/inventory/etc.)
- KMS key/alias for Publishing Destination and S3 SSE + key policy
- CloudWatch Event Rule triggered on GuardDuty Findings + Log Group / Event Target

## Example

```hcl
module "guardduty_usw2" {
  source = "github.com/18F/identity-terraform//guardduty?ref=main"

  region              = "us-west-2"
  bucket_name_prefix  = local.bucket_name_prefix
  finding_freq        = "SIX_HOURS"
  enabled_features = [
    "S3_DATA_EVENTS",
    "EKS_AUDIT_LOGS",
    "EBS_MALWARE_PROTECTION",
    "EKS_RUNTIME_MONITORING",
    "EKS_ADDON_MANAGEMENT"
  ]
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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_guardduty_bucket_config"></a> [guardduty\_bucket\_config](#module\_guardduty\_bucket\_config) | github.com/18F/identity-terraform//s3_config | 91f5c8a84c664fc5116ef970a5896c2edadff2b1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.guardduty_findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.guardduty_findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.guardduty_findings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_resource_policy.delivery_events_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy) | resource |
| [aws_guardduty_detector.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_detector_feature.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_detector_feature.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector_feature) | resource |
| [aws_guardduty_publishing_destination.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_publishing_destination) | resource |
| [aws_kms_alias.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.delivery_events_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.guardduty_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.guardduty_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Second substring in S3 bucket name of<br/>$bucket\_name\_prefix.$bucket\_name.$account\_id-$region. | `string` | `"guardduty"` | no |
| <a name="input_bucket_name_override"></a> [bucket\_name\_override](#input\_bucket\_name\_override) | Set this to override the normal bucket naming schema. | `string` | `""` | no |
| <a name="input_bucket_name_prefix"></a> [bucket\_name\_prefix](#input\_bucket\_name\_prefix) | First substring in S3 bucket name of<br/>$bucket\_name\_prefix.$bucket\_name.$account\_id-$region. | `string` | n/a | yes |
| <a name="input_cloudwatch_name"></a> [cloudwatch\_name](#input\_cloudwatch\_name) | Name for the GuardDuty Findings CloudWatch Target/Event/Rule. | `string` | `"GuardDutyFindings"` | no |
| <a name="input_enabled_features"></a> [enabled\_features](#input\_enabled\_features) | List of GuardDuty Features to set to ENABLED for the aws\_guardduty\_detector.main resource. | `list(string)` | `[]` | no |
| <a name="input_event_target_id"></a> [event\_target\_id](#input\_event\_target\_id) | ID for the Event Target used for CloudWatch Logs. | `string` | `"SendToCWLogGroup"` | no |
| <a name="input_finding_freq"></a> [finding\_freq](#input\_finding\_freq) | Frequency of notifications for GuardDuty findings. | `string` | `"SIX_HOURS"` | no |
| <a name="input_inventory_bucket_arn"></a> [inventory\_bucket\_arn](#input\_inventory\_bucket\_arn) | Override ARN of the S3 Inventory reports bucket.<br/>Defaults to arn:aws:s3:::$bucket\_name\_prefix.s3-inventory.$account\_id-$region<br/>if not explicitly declared. | `string` | `""` | no |
| <a name="input_log_bucket_name"></a> [log\_bucket\_name](#input\_log\_bucket\_name) | Override name of the bucket used for S3 logging.<br/>Will default to $bucket\_name\_prefix.s3-access-logs.$account\_id-$region<br/>if not explicitly declared. | `string` | `""` | no |
| <a name="input_log_group_id"></a> [log\_group\_id](#input\_log\_group\_id) | ID of the CloudWatch Log Group to log GuardDuty findings. | `string` | `"/aws/events/gdfindings"` | no |
| <a name="input_publishing_policy_name"></a> [publishing\_policy\_name](#input\_publishing\_policy\_name) | Name of the CloudWatch Log Resource Policy used for log delivery. | `string` | `"cw-rule-log-publishing-policy"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region for the module. | `string` | `"us-west-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cw_log_group"></a> [cw\_log\_group](#output\_cw\_log\_group) | Name of the GuardDuty Findings CloudWatch Log Group. |
| <a name="output_detector_id"></a> [detector\_id](#output\_detector\_id) | ID of the GuardDuty Detector. |
| <a name="output_kms_key_alias"></a> [kms\_key\_alias](#output\_kms\_key\_alias) | Alias of the KMS key used to encrypt GuardDuty publishing. |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ID of the KMS key used to encrypt GuardDuty publishing. |
| <a name="output_publishing_destination"></a> [publishing\_destination](#output\_publishing\_destination) | ID of the GuardDuty Publishing Destination (S3). |
<!-- END_TF_DOCS -->