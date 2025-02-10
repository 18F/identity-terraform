# `slack_lambda`

This Terraform module is designed to create a Lambda function, containing Python code, which will send a message to a Slack channel any time a message is published to a specified SNS topic. It will create all necessary resources for this, including:

- Lambda function + IAM role/policy
- CloudWatch log group
- SNS execution permission for the Lambda
- SNS topic subscription
- KMS SSE

***NOTE:*** The SNS topic you're publishing to must already exist, and you must provide its ARN for the variable `slack_topic_arn` in order for the module to build correctly.

## Caveat -- Read This First!

Due to the way Terraform's `archive_file` function renders the `zip` file each time it runs, it updates the `last_modified` and `source_code_hash` attributes for the Lambda function each time it runs -- even though the underlying code has not changed. This is true even with using a `local_file` resource, as it regenerates the file each time. As a result, an `ignore_changes` lifecycle block is included in the `aws_lambda_function` resource, which will make it skip checking the above attributes each time it runs.

If you make any changes to any of the variables used in the actual code, you'll need to comment out the `lifecycle` block in your local clone, run `apply`, and then uncomment it again.

## Example

```hcl
resource "aws_sns_topic" "slack_otherevents" {
  name = "slack-otherevents"
}

module "slack_login_otherevents" {
  source = "github.com/18F/identity-terraform//slack_lambda?ref=main"

  lambda_name        = "snstoslack_login_otherevents"
  lambda_description = "Sends messages to #login-otherevents Slack channel via SNS subscription."
  slack_webhook_url  = data.aws_s3_bucket_object.slack_webhook.body
  slack_channel      = "login-otherevents"
  slack_username     = var.slack_username
  slack_icon         = var.slack_icon
  slack_topic_arn    = aws_sns_topic.slack_otherevents.arn
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
| <a name="module_slack_lambda"></a> [slack\_lambda](#module\_slack\_lambda) | github.com/18F/identity-terraform//lambda_function | 026f69d0a5e2b8af458888a5f21a72d557bbe1fe |

## Resources

| Name | Type |
|------|------|
| [aws_lambda_permission.allow_sns_trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sns_topic_subscription.sns_to_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_lambda_description"></a> [lambda\_description](#input\_lambda\_description) | Lambda description | `string` | `"Sends a message sent to an SNS topic to Slack."` | no |
| <a name="input_lambda_memory"></a> [lambda\_memory](#input\_lambda\_memory) | Memory allocated to Lambda function, 128MB to 3,008MB in 64MB increments | `number` | `128` | no |
| <a name="input_lambda_name"></a> [lambda\_name](#input\_lambda\_name) | Name of the Lambda function | `string` | `"SnsToSlack"` | no |
| <a name="input_lambda_runtime"></a> [lambda\_runtime](#input\_lambda\_runtime) | Lambda runtime | `string` | `"python3.12"` | no |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Timeout for Lambda function | `number` | `120` | no |
| <a name="input_slack_alarm_emoji"></a> [slack\_alarm\_emoji](#input\_slack\_alarm\_emoji) | Emoji used by Slack for a CloudWatch ALARM message. | `string` | `":large_red_square:"` | no |
| <a name="input_slack_channel"></a> [slack\_channel](#input\_slack\_channel) | Name of the Slack channel to send messages to. DO NOT include the # sign. | `string` | n/a | yes |
| <a name="input_slack_icon"></a> [slack\_icon](#input\_slack\_icon) | Displayed icon used by Slack for the message. | `string` | n/a | yes |
| <a name="input_slack_notice_emoji"></a> [slack\_notice\_emoji](#input\_slack\_notice\_emoji) | Emoji used by Slack for a Lambda NOTICE message. | `string` | `":large_yellow_square:"` | no |
| <a name="input_slack_ok_emoji"></a> [slack\_ok\_emoji](#input\_slack\_ok\_emoji) | Emoji used by Slack for a CloudWatch OK message. | `string` | `":large_green_square:"` | no |
| <a name="input_slack_topic_arn"></a> [slack\_topic\_arn](#input\_slack\_topic\_arn) | ARN of the SNS topic for the Lambda to subscribe to. | `string` | n/a | yes |
| <a name="input_slack_username"></a> [slack\_username](#input\_slack\_username) | Displayed username of the posted message. | `string` | n/a | yes |
| <a name="input_slack_warn_emoji"></a> [slack\_warn\_emoji](#input\_slack\_warn\_emoji) | Emoji used by Slack for a Lambda WARN message. | `string` | `":large_orange_square:"` | no |
| <a name="input_slack_webhook_url_parameter"></a> [slack\_webhook\_url\_parameter](#input\_slack\_webhook\_url\_parameter) | Slack Webhook URL SSM Parameter. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cw_log_group"></a> [cw\_log\_group](#output\_cw\_log\_group) | Name of the CloudWatch Log Group for the slack\_lambda function. |
<!-- END_TF_DOCS -->
