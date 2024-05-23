# lambda_insights module

This module provides the minimum resources required for finding the insights layer ARN and required IAM policy. 

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
| [aws_iam_policy.insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_lambda_insights_account"></a> [lambda\_insights\_account](#input\_lambda\_insights\_account) | The lambda insights account provided by AWS for monitoring | `string` | `"580247275435"` | no |
| <a name="input_lambda_insights_version"></a> [lambda\_insights\_version](#input\_lambda\_insights\_version) | The lambda insights layer version to use for monitoring | `number` | `52` | no |
| <a name="input_region"></a> [region](#input\_region) | Target AWS Region | `string` | `"us-west-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_policy_arn"></a> [iam\_policy\_arn](#output\_iam\_policy\_arn) | The IAM Policy ARN for attaching to iam\_roles for writing to insights |
| <a name="output_layer_arn"></a> [layer\_arn](#output\_layer\_arn) | The insights lambda layer arn for attaching to aws\_lambda\_functions |
<!-- END_TF_DOCS -->
