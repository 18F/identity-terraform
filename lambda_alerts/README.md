# Lambda Alerts

This module uses CloudWatch metrics to create alarms on AWS Lambda errors

<!-- BEGIN_TF_DOCS -->
```hcl
module "foo_bar" {
  source = "github.com/18F/identity-terraform//lambda_alerts"

  enabled              = 1
  function_name        = local.ct_requeue_lambda_name
  alarm_actions        = var.alarm_sns_topic_arns
  error_rate_threshold = 5 # percent
  datapoints_to_alarm  = 1
  evaluation_periods   = 5
  insights_enabled     = true
  duration_setting     = aws_lambda_function.cloudtrail_requeue.timeout
}
```

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
| <a name="input_datapoints_to_alarm"></a> [datapoints\_to\_alarm](#input\_datapoints\_to\_alarm) | The number of datapoints that must be breaching to trigger the alarm. | `number` | `1` | no |
| <a name="input_duration_setting"></a> [duration\_setting](#input\_duration\_setting) | The duration setting of the lambda to monitor (in seconds) | `number` | n/a | yes |
| <a name="input_duration_threshold"></a> [duration\_threshold](#input\_duration\_threshold) | The duration threshold (as a percentage) for triggering an alert | `number` | `80` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether or not to create the Lambda alert monitor. | `number` | `1` | no |
| <a name="input_error_rate_threshold"></a> [error\_rate\_threshold](#input\_error\_rate\_threshold) | The threshold error rate (as a percentage) for triggering an alert | `number` | `1` | no |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | n/a | `number` | `1` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Name of the lambda function to monitor | `string` | n/a | yes |
| <a name="input_insights_enabled"></a> [insights\_enabled](#input\_insights\_enabled) | Creates lambda insights specific alerts | `bool` | `false` | no |
| <a name="input_memory_usage_threshold"></a> [memory\_usage\_threshold](#input\_memory\_usage\_threshold) | The threshold memory utilization (as a percentage) for triggering an alert | `number` | `90` | no |
| <a name="input_period"></a> [period](#input\_period) | The period in seconds over which the specified statistic is applied. | `number` | `60` | no |
| <a name="input_treat_missing_data"></a> [treat\_missing\_data](#input\_treat\_missing\_data) | n/a | `string` | `"missing"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->