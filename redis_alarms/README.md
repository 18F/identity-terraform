# `redis_alarms`

This Terraform module creates a set of AWS CloudWatch Metric Alarms, which follow/are triggered by metrics from a specified Redis OSS ElastiCache cache cluster. These fall primarily into three categories:

1. 'Simple threshold' alarms (i.e. following `comparison_operator = "GreaterThanOrEqualToThreshold"`), marked as/sending to a 'high priority' notification ARN
2. Same as #1, but marked as/sending to a 'CRITICAL priority' notification ARN (useful when needing multiple thresholds and/or alarm destinations for a single metric)
3. A 'network utilization threshold' alarm, which fires off when the `NetworkBytesIn` + `NetworkBytesOut` throughput total exceeds the percentage specified by `var.threshold_network` -- dynamically calculated based on the type/size of node used for the target cache cluster

## Example

```hcl
module "redis_alarm" {
  source = "github.com/18F/identity-terraform//redis_alarms?ref=main"

  cluster_id                 = var.redis_cluster_id
  alarms_map                 = var.alarms_map
  high_alarm_action_arns     = var.high_alarm_action_arns
  critical_alarm_action_arns = var.critical_alarm_action_arns
  period_duration            = var.period_duration
  runbook_url                = var.runbook_url
  node_type                  = trimprefix(var.node_type, "cache.")
  threshold_network          = var.threshold_network
}
```

***NOTE:*** This module is designed to be pointed at a _single_ cache cluster within an ElastiCache replication group. Due to restrictions of the AWS API, Terraform can't determine the complete `member_clusters` list of an `aws_elasticache_replication_group` resource if said resource does not yet exist; thus, if using `for_each` to point this module at every cluster within a replication group (as declared/created in Terraform code), the following code should be a good basis for generating a list of cache cluster IDs that can be passed into the `for_each` attribute of the `module` block:

```hcl
  for_each = toset([
    for i in range(1, (var.num_cache_clusters + 1)) : format("%s-%03d", local.cluster_id, i)
  ])
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

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.redis_critical](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.redis_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.redis_network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ec2_instance_type.cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarms_map"></a> [alarms\_map](#input\_alarms\_map) | Map detailing the configuration for each simple metric alarm to create<br/>for the ElastiCache Redis cache cluster specified by var.cluster\_id below.<br/>Must follow the full format (keys/values) specified above; the 'default'<br/>value below can be used as an example for adding more alarms. | <pre>map(object({<br/>    alarm_name         = string<br/>    metric_name        = string<br/>    evaluation_periods = number<br/>    threshold_high     = string<br/>    threshold_critical = string<br/>    alarm_descriptor   = string<br/>  }))</pre> | <pre>{<br/>  "cpu": {<br/>    "alarm_descriptor": "CPU utilization",<br/>    "alarm_name": "CPU",<br/>    "evaluation_periods": 1,<br/>    "metric_name": "CPUUtilization",<br/>    "threshold_critical": 80,<br/>    "threshold_high": 70<br/>  },<br/>  "currconnections": {<br/>    "alarm_descriptor": "connections",<br/>    "alarm_name": "CurrConnections",<br/>    "evaluation_periods": 2,<br/>    "metric_name": "CurrConnections",<br/>    "threshold_critical": 50000,<br/>    "threshold_high": 40000<br/>  },<br/>  "memory": {<br/>    "alarm_descriptor": "memory utilization",<br/>    "alarm_name": "Memory",<br/>    "evaluation_periods": 1,<br/>    "metric_name": "DatabaseMemoryUsagePercentage",<br/>    "threshold_critical": 80,<br/>    "threshold_high": 75<br/>  },<br/>  "replication_lag": {<br/>    "alarm_descriptor": "replication lag",<br/>    "alarm_name": "ReplicationLag",<br/>    "evaluation_periods": 1,<br/>    "metric_name": "ReplicationLag",<br/>    "threshold_critical": ".2",<br/>    "threshold_high": ".1"<br/>  }<br/>}</pre> | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | ID of the cache cluster that the alarms are created for. | `string` | n/a | yes |
| <a name="input_critical_alarm_action_arns"></a> [critical\_alarm\_action\_arns](#input\_critical\_alarm\_action\_arns) | List of actions to execute when the 'critical'/'network' alarms<br/>transition into an ALARM state from any other state.<br/>Each MUST be specified as an Amazon Resource Name (ARN). | `list(string)` | n/a | yes |
| <a name="input_high_alarm_action_arns"></a> [high\_alarm\_action\_arns](#input\_high\_alarm\_action\_arns) | List of actions to execute when the 'high' alarms<br/>transition into an ALARM state from any other state.<br/>Each MUST be specified as an Amazon Resource Name (ARN). | `list(string)` | n/a | yes |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | Type of node (specifically an EC2 instance type, i.e. WITHOUT 'cache.' prefix)<br/>used by the Redis cache cluster. MUST point to an EC2 instance/node type that<br/>has a NetworkPerformance value of 'Up to 5 Gigabit' or higher, or the threshold<br/>calculations for the 'redis\_network' resource cannot be set properly. | `string` | n/a | yes |
| <a name="input_period_duration"></a> [period\_duration](#input\_period\_duration) | Duration (in seconds) per evaluation period, for 'high' and 'critical' alarms. | `number` | `60` | no |
| <a name="input_runbook_url"></a> [runbook\_url](#input\_runbook\_url) | Link to a runbook to include in the alert description. | `string` | n/a | yes |
| <a name="input_threshold_network"></a> [threshold\_network](#input\_threshold\_network) | Percentage of network utilization (whole numbers only) used as threshold for<br/>the 'redis\_network' resource. Alarm will fire when this percentage is reached<br/>at least 1 time in 60 seconds. | `number` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->