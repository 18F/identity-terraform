# `guardduty`

This module creates and manages a GuardDuty Detector for an AWS account (in a single region), along with associated resources:

- S3 bucket used as a GuardDuty Publishing Destination + config resources (lifecycle/policy/logging/inventory/etc.)
- KMS key/alias for Publishing Destination and S3 SSE + key policy
- CloudWatch Event Rule triggered on GuardDuty Findings + Log Group / Event Target

## Example

```hcl
module "guardduty_usw2" {
  source = "github.com/18F/identity-terraform//guardduty?ref=main"

  region                     = "us-west-2"
  bucket_name_prefix         = local.bucket_name_prefix
  guardduty_finding_freq     = "SIX_HOURS"
  guardduty_s3_enable        = true
  guardduty_k8s_audit_enable = false
  guardduty_ec2_ebs_enable   = false
}
```

## Variables

| Name                    | Type   | Description                                                                                                                                                  | Required | Default                  |
| -----                   | -----  | -----                                                                                                                                                        | -----    | -----                    |
| `region`                | string | AWS Region for the module.                                                                                                                                   | YES      | `us-west-2`              |
| `bucket_name`           | string | Second substring in S3 bucket name of `$bucket_name_prefix.$bucket_name.$account_id-$region`.                                                                | YES      | `guardduty`              |
| `bucket_name_prefix`    | string | First substring in S3 bucket name of `$bucket_name_prefix.$bucket_name.$account_id-$region`.                                                                 | YES      | N/A                      |
| `bucket_name_override`  | string | Set this to override the normal bucket naming schema.                                                                                                        | NO       | N/A                      |
| `log_bucket_name`       | string | Override name of the bucket used for S3 logging. Will default to `$bucket_name_prefix.s3-access-logs.$account_id-$region` if not explicitly declared.        | NO       | N/A                      |
| `inventory_bucket_arn`  | string | Override ARN of the S3 Inventory reports bucket. Defaults to `arn:aws:s3:::$bucket_name_prefix.s3-inventory.$account_id-$region` if not explicitly declared. | NO       | N/A                      |
| `finding_freq`          | string | Frequency of notifications for GuardDuty findings.                                                                                                           | YES      | `SIX_HOURS`              |
| `s3_enable`             | bool   | Whether or not to enable S3 protection in GuardDuty.                                                                                                         | YES      | **false**                |
| `k8s_audit_enable`      | bool   | Whether or not to enable Kubernetes audit logs as a data source for Kubernetes protection (via GuardDuty).                                                   | YES      | **false**                |
| `ec2_ebs_enable`        | bool   | Whether or not to enable Malware Protection (via scanning EBS volumes) as a data source for EC2 instances (via GuardDuty).                                   | YES      | **false**                |
| `event_rule_prefix`     | string | Prefix string used to name the GuardDuty Findings CloudWatch Event Rule in the form `$event_rule_prefix-$region.`                                            | YES      | `GuardDutyFindings`      |
| `log_group_name`        | string | Name of the CloudWatch Log Group to log GuardDuty findings.                                                                                                  | YES      | `/aws/events/gdfindings` |
| `event_target_id`       | string | ID for the Event Target used for CloudWatch Logs.                                                                                                            | YES      | `GDFindingsToCWLogs`     |

## Outputs

| Name                     | Description                                                | Value                                              |
| -----                    | -----                                                      | -----                                              |
| `detector_id`            | ID of the GuardDuty Detector.                              | `aws_guardduty_detector.main.id`                   |
| `publishing_destination` | ID of the GuardDuty Publishing Destination (S3).           | `aws_guardduty_publishing_destination.s3.id`       |
| `cw_log_group`           | Name of the GuardDuty Findings CloudWatch Log Group.       | `aws_cloudwatch_log_group.guardduty_findings.name` |
| `kms_key_id`             | ID of the KMS key used to encrypt GuardDuty publishing.    | `aws_kms_key.guardduty.key_id`                     |
| `kms_key_alias`          | Alias of the KMS key used to encrypt GuardDuty publishing. | `aws_kms_alias.guardduty.name`                     |
