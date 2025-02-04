# lambda_function module

This module provides a consistent framework for creating and monitoring Lambda functions.

```terraform
module "sample_function" {
  #source = "github.com/18F/identity-terraform//lambda_function?ref="
  source = "../../../../identity-terraform/lambda_function"

  # lambda function
  region               = var.region
  function_name        = "sample-function"
  description          = "My sample function"
  source_code_filename = "sample_function.py"
  source_dir           = "${path.module}/lambda/aws-audit"
  runtime              = "python3.12"

  environment_variables = {
    ENVVAR1 = "Environment variable 1"
    ENVVAR2 = "Environment variable 2"
  }

  # Logging and alarms
  cloudwatch_retention_days = var.cloudwatch_retention_days
  alarm_actions             = [var.slack_notification_arn]
  treat_missing_data        = "notBreaching"

  # Lambda trigger (EventBridge event or schedule)
  schedule_expression = "rate(1 day)"

  # IAM permissions
  lambda_iam_policy_document = data.aws_iam_policy_document.custom_permissions.json
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
| <a name="module_lambda_alerts"></a> [lambda\_alerts](#module\_lambda\_alerts) | github.com/18F/identity-terraform//lambda_alerts | a4dfd80b0e40a96d2a0c7c09262f84d2ea3d9104 |
| <a name="module_lambda_code"></a> [lambda\_code](#module\_lambda\_code) | github.com/18F/identity-terraform//null_archive | 2d05076e1d089d9e9ab251fa0f11a2e2ceb132a3 |
| <a name="module_lambda_insights"></a> [lambda\_insights](#module\_lambda\_insights) | github.com/18F/identity-terraform//lambda_insights | 5c1a8fb0ca08aa5fa01a754a40ceab6c8075d4c9 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_iam_policy_document.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_actions"></a> [alarm\_actions](#input\_alarm\_actions) | ARNs for Cloudwatch Alarm actions | `list(any)` | n/a | yes |
| <a name="input_cloudwatch_retention_days"></a> [cloudwatch\_retention\_days](#input\_cloudwatch\_retention\_days) | n/a | `number` | `2192` | no |
| <a name="input_datapoints_to_alarm"></a> [datapoints\_to\_alarm](#input\_datapoints\_to\_alarm) | The number of datapoints that must be breaching to trigger the alarm. | `number` | `1` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the Lambda function | `string` | n/a | yes |
| <a name="input_duration_alarm_description"></a> [duration\_alarm\_description](#input\_duration\_alarm\_description) | Overrides the default alarm description for duration alarm | `string` | `""` | no |
| <a name="input_duration_alarm_name_override"></a> [duration\_alarm\_name\_override](#input\_duration\_alarm\_name\_override) | Overrides the default alarm naming convention with a custom name | `string` | `""` | no |
| <a name="input_duration_threshold"></a> [duration\_threshold](#input\_duration\_threshold) | The duration threshold (as a percentage) for triggering an alert | `number` | `80` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether or not to create the Lambda alert monitor. | `number` | `1` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Name of the environment in which the lambda function lives | `string` | `""` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables for the Lambda function. Individual variables must be<br/>  of a type that terraform can convert to strings. Lists and maps must be<br/>  `jsonencode`ed. | `map(any)` | n/a | yes |
| <a name="input_error_rate_alarm_description"></a> [error\_rate\_alarm\_description](#input\_error\_rate\_alarm\_description) | Overrides the default alarm description for error rate alarm | `string` | `""` | no |
| <a name="input_error_rate_alarm_name_override"></a> [error\_rate\_alarm\_name\_override](#input\_error\_rate\_alarm\_name\_override) | Overrides the default alarm naming convention with a custom name | `string` | `""` | no |
| <a name="input_error_rate_operator"></a> [error\_rate\_operator](#input\_error\_rate\_operator) | The operator used to compare a calculated error rate against a threshold | `string` | `"GreaterThanOrEqualToThreshold"` | no |
| <a name="input_error_rate_threshold"></a> [error\_rate\_threshold](#input\_error\_rate\_threshold) | The threshold error rate (as a percentage) for triggering an alert | `number` | `1` | no |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | n/a | `number` | `1` | no |
| <a name="input_event_pattern"></a> [event\_pattern](#input\_event\_pattern) | EventBridge pattern to trigger lambda | `string` | `""` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Name of the Lambda function | `string` | n/a | yes |
| <a name="input_handler"></a> [handler](#input\_handler) | Full Lambda handler string | `string` | `""` | no |
| <a name="input_handler_function_name"></a> [handler\_function\_name](#input\_handler\_function\_name) | Lambda handler function name | `string` | `"lambda_handler"` | no |
| <a name="input_insights_enabled"></a> [insights\_enabled](#input\_insights\_enabled) | Whether the lambda has Lambda Insights enabled | `bool` | `true` | no |
| <a name="input_lambda_iam_policy_document"></a> [lambda\_iam\_policy\_document](#input\_lambda\_iam\_policy\_document) | IAM permissions for the lambda function. Use a data.aws\_iam\_policy\_document to construct | `string` | `""` | no |
| <a name="input_lambda_iam_role_name"></a> [lambda\_iam\_role\_name](#input\_lambda\_iam\_role\_name) | Role name override for resources that need underscores.<br/>If not specified, will set the role name to the default of '{var.function\_name}-lambda-role'<br/>If var.role\_name\_prefix is set, the module will use the name prefix instead of the role name | `string` | `null` | no |
| <a name="input_layers"></a> [layers](#input\_layers) | List of layers for the lambda function | `list(any)` | `[]` | no |
| <a name="input_log_skip_destroy"></a> [log\_skip\_destroy](#input\_log\_skip\_destroy) | Skip log destruction | `bool` | `false` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Memory allocated to the Lambda function | `string` | `"128"` | no |
| <a name="input_memory_usage_alarm_description"></a> [memory\_usage\_alarm\_description](#input\_memory\_usage\_alarm\_description) | Overrides the default alarm description for memory usage alarm | `string` | `""` | no |
| <a name="input_memory_usage_alarm_name_override"></a> [memory\_usage\_alarm\_name\_override](#input\_memory\_usage\_alarm\_name\_override) | Overrides the default alarm naming convention with a custom name | `string` | `""` | no |
| <a name="input_memory_usage_threshold"></a> [memory\_usage\_threshold](#input\_memory\_usage\_threshold) | The threshold memory utilization (as a percentage) for triggering an alert | `number` | `90` | no |
| <a name="input_ok_actions"></a> [ok\_actions](#input\_ok\_actions) | ARNs for Cloudwatch OK actions | `list(any)` | `[]` | no |
| <a name="input_period"></a> [period](#input\_period) | The period in seconds over which the specified statistic is applied. | `number` | `60` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-west-2"` | no |
| <a name="input_reserved_concurrent_executions"></a> [reserved\_concurrent\_executions](#input\_reserved\_concurrent\_executions) | The max number concurrent invocations allowed for the Lambda | `number` | `-1` | no |
| <a name="input_role_name_prefix"></a> [role\_name\_prefix](#input\_role\_name\_prefix) | Prefix string used to specify the name of the function's IAM role.<br/>Required if creating the same function in multiple regions.<br/>If not specified, will set the role name to the value of<br/>var.lambda\_iam\_role\_name or the default of '{var.function\_name}-lambda-role' | `string` | `null` | no |
| <a name="input_runbook"></a> [runbook](#input\_runbook) | A link to a runbook associated with any metric in this module | `string` | `""` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Lambda function runtime | `string` | n/a | yes |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | Cron or rate expression to trigger lambda | `string` | `""` | no |
| <a name="input_source_code_filename"></a> [source\_code\_filename](#input\_source\_code\_filename) | Name of the file containing the Lambda source code | `string` | n/a | yes |
| <a name="input_source_dir"></a> [source\_dir](#input\_source\_dir) | Directory containing the Lambda source code | `string` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Lambda timeout | `number` | `120` | no |
| <a name="input_treat_missing_data"></a> [treat\_missing\_data](#input\_treat\_missing\_data) | n/a | `string` | `"nonBreaching"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | n/a |
| <a name="output_lambda_arn"></a> [lambda\_arn](#output\_lambda\_arn) | The ARN of the Lambda Function |
| <a name="output_lambda_role_name"></a> [lambda\_role\_name](#output\_lambda\_role\_name) | The name of the IAM Role associated with the lambda |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | The name of the cloudwatch log group associated with the lambda |
<!-- END_TF_DOCS -->
