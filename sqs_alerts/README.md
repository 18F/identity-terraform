# SQS Alerts

This module uses CloudWatch metrics to create common alarms on SQS Queues.

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
| [aws_cloudwatch_metric_alarm.age_of_oldest_message](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.inflight_messages](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.message_size](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_age_of_oldest_message_threshold"></a> [age\_of\_oldest\_message\_threshold](#input\_age\_of\_oldest\_message\_threshold) | The threshold for age\_of\_oldest\_message. Defined in seconds. | `number` | `300` | no |
| <a name="input_alarm_actions"></a> [alarm\_actions](#input\_alarm\_actions) | A list of ARNs to notify when the alarm fires | `list(string)` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Enables the set of alerts defined in this module | `bool` | `true` | no |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | n/a | `number` | `1` | no |
| <a name="input_inflight_threshold"></a> [inflight\_threshold](#input\_inflight\_threshold) | The percentile threshold of inflight messages | `number` | `80` | no |
| <a name="input_max_message_size"></a> [max\_message\_size](#input\_max\_message\_size) | The maximum message size supported by the queue | `number` | n/a | yes |
| <a name="input_message_size_threshold"></a> [message\_size\_threshold](#input\_message\_size\_threshold) | The percentile threshold of message sizes | `number` | `80` | no |
| <a name="input_ok_actions"></a> [ok\_actions](#input\_ok\_actions) | A list of ARNs to notify when the alarm returns to an OK state | `list(string)` | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | The period in seconds over which the specified statistic is applied | `number` | `60` | no |
| <a name="input_queue_name"></a> [queue\_name](#input\_queue\_name) | The name of the SQS queue to monitor | `string` | n/a | yes |
| <a name="input_queue_type"></a> [queue\_type](#input\_queue\_type) | The type of SQS queue to monitor | `string` | `"standard"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->