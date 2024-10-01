# Lambda Alerts

This module uses CloudWatch metrics to create alarms on AWS Lambda errors

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
| [aws_cloudwatch_metric_alarm.lambda_duration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_error_rate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_memory_usage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_actions"></a> [alarm\_actions](#input\_alarm\_actions) | A list of ARNs to notify when the alarm fires | `list(string)` | n/a | yes |
| <a name="input_duration_setting"></a> [duration\_setting](#input\_duration\_setting) | The duration setting of the lambda to monitor (in seconds) | `number` | n/a | yes |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Name of the lambda function to monitor | `string` | n/a | yes |
| <a name="input_datapoints_to_alarm"></a> [datapoints\_to\_alarm](#input\_datapoints\_to\_alarm) | The number of datapoints that must be breaching to trigger the alarm. | `number` | `1` | no |
| <a name="input_duration_alarm_description"></a> [duration\_alarm\_description](#input\_duration\_alarm\_description) | Overrides the default alarm description for duration alarm | `string` | `""` | no |
| <a name="input_duration_alarm_name_override"></a> [duration\_alarm\_name\_override](#input\_duration\_alarm\_name\_override) | Overrides the default alarm naming convention with a custom name | `string` | `""` | no |
| <a name="input_duration_threshold"></a> [duration\_threshold](#input\_duration\_threshold) | The duration threshold (as a percentage) for triggering an alert | `number` | `80` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether or not to create the Lambda alert monitor. | `number` | `1` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Name of the environment in which the lambda function lives | `string` | `""` | no |
| <a name="input_error_rate_alarm_description"></a> [error\_rate\_alarm\_description](#input\_error\_rate\_alarm\_description) | Overrides the default alarm description for error rate alarm | `string` | `""` | no |
| <a name="input_error_rate_alarm_name_override"></a> [error\_rate\_alarm\_name\_override](#input\_error\_rate\_alarm\_name\_override) | Overrides the default alarm naming convention with a custom name | `string` | `""` | no |
| <a name="input_error_rate_operator"></a> [error\_rate\_operator](#input\_error\_rate\_operator) | The operator used to compare a calculated error rate against a threshold | `string` | `"GreaterThanOrEqualToThreshold"` | no |
| <a name="input_error_rate_threshold"></a> [error\_rate\_threshold](#input\_error\_rate\_threshold) | The threshold error rate (as a percentage) for triggering an alert | `number` | `1` | no |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | n/a | `number` | `1` | no |
| <a name="input_insights_enabled"></a> [insights\_enabled](#input\_insights\_enabled) | Creates lambda insights specific alerts | `bool` | `false` | no |
| <a name="input_memory_usage_alarm_description"></a> [memory\_usage\_alarm\_description](#input\_memory\_usage\_alarm\_description) | Overrides the default alarm description for memory usage alarm | `string` | `""` | no |
| <a name="input_memory_usage_alarm_name_override"></a> [memory\_usage\_alarm\_name\_override](#input\_memory\_usage\_alarm\_name\_override) | Overrides the default alarm naming convention with a custom name | `string` | `""` | no |
| <a name="input_memory_usage_threshold"></a> [memory\_usage\_threshold](#input\_memory\_usage\_threshold) | The threshold memory utilization (as a percentage) for triggering an alert | `number` | `90` | no |
| <a name="input_ok_actions"></a> [ok\_actions](#input\_ok\_actions) | A list of ARNs to notify when the alarm goes to ok state | `list(string)` | `[]` | no |
| <a name="input_period"></a> [period](#input\_period) | The period in seconds over which the specified statistic is applied. | `number` | `60` | no |
| <a name="input_runbook"></a> [runbook](#input\_runbook) | A link to a runbook associated with any metric in this module | `string` | `""` | no |
| <a name="input_treat_missing_data"></a> [treat\_missing\_data](#input\_treat\_missing\_data) | n/a | `string` | `"missing"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->