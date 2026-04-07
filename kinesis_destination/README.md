# `kinesis_destination`

This module creates and manages a CloudWatch Logs Destination, which is used to send data to an externally-created Kinesis resource (either a Data Stream or a Firehose delivery stream) in the same account. It also adds an IAM policy to the Destination so that CloudWatch Subscription Filters can be pointed to it (both individual and account-level Subscription Filters), allowing any number of log groups to send to the same Kinesis resource.

Both the Kinesis resource _and_ the Destination(s) must be in the same _account_. However, this module may be called multiple times to create additional CloudWatch Logs Destinations in separate _regions_, if desired.

## Example

```hcl
#### Kinesis Data Stream already created in us-west-2 ####

# create Destination in us-west-2 that accepts Subscription Filters/Logs from two AWS accounts
module "kinesis_stream_destination_uw2" {
  source = "github.com/18F/identity-terraform//kinesis_destination?ref=main"
  providers = {
    aws = aws.usw2
  }

  kinesis_arn        = aws_kinesis_stream.logarchive.arn
  source_account_ids = ["111111111111", "222222222222"]
}

# create Destination in us-east-1 which points to Firehose in us-west-2, logging only one AWS account
module "kinesis_firehose_destination_ue1" {
  source = "github.com/18F/identity-terraform//kinesis_destination?ref=main"
  providers = {
    aws = aws.use1
  }

  kinesis_arn        = aws_kinesis_firehose_delivery_stream.logarchive.arn
  source_account_ids = ["111111111111"]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.5 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_destination.kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination) | resource |
| [aws_cloudwatch_log_destination_policy.subscription_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination_policy) | resource |
| [aws_iam_role.cloudwatch_to_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cloudwatch_kinesis_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudwatch_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudwatch_kinesis_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.subscription_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kinesis_arn"></a> [kinesis\_arn](#input\_kinesis\_arn) | ARN of the Kinesis resource (Firehose/Data Stream) that the Destination points to. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region for the module. | `string` | `"us-west-2"` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Identifier string used to name the IAM role/policies used by CloudWatch Logs for accessing the<br/>Kinesis resource/CloudWatch Destinations, and the name of the CloudWatch Destination itself.<br/>Passed into resources as "`var.role_name`-`var.region`". | `string` | `""` | no |
| <a name="input_source_account_ids"></a> [source\_account\_ids](#input\_source\_account\_ids) | ID(s) of the AWS Account(s) where log data will be sent FROM. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kinesis_destination_arn"></a> [kinesis\_destination\_arn](#output\_kinesis\_destination\_arn) | ARN of the CloudWatch Logs Destination for the Kinesis resource. |
<!-- END_TF_DOCS -->
