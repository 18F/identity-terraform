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

## Variables

`lambda_name` - Name of the Lambda function.
`lambda_description` - Description for the Lambda function.
`lambda_timeout` - Timeout value for the Lambda function.
`lambda_memory` - Memory allocated to Lambda function, 128MB to 3,008MB in 64MB increments.
`lambda_runtime` - Lambda runtime (offered as a variable, but should be set to `python3.12` to function properly)
`slack_webhook_url` - Slack Webhook URL.
`slack_channel` - Name of the Slack channel to send messages to. *DO NOT include the # sign.*
`slack_username` - Displayed username of the posted message.
`slack_icon` - Displayed icon used by Slack for the message.
`slack_topic_arn` - ARN of the SNS topic for the Lambda to subscribe to.
