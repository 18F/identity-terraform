# `redis_elasticache`

This Terraform module creates the basic set of resources needed for working with a Redis OSS cluster within AWS ElastiCache, including:

- An ElastiCache replication group, running on a `redis` engine as specified by `var.engine_version`
- An ElastiCache parameter group for said replication group, based on the parameter group family identifier specified by `var.family_name`
- A CloudWatch Log Group used to capture events from said replication group
- A set of CloudWatch Metric Alarms -- created via [the `redis_alarms` module from this same repo!](https://github.com/18F/identity-terraform/tree/main/redis_alarms/) -- which track/alert on any specified metrics within the `AWS/ElastiCache` namespace, along with an alarm created specifically to track the `NetworkBytesIn` + `NetworkBytesOut` throughput total against the percentage specified by `var.threshold_network` -- dynamically calculated based on the type/size of node used for each cache cluster in the replication group

***NOTE:*** The following resources, required by this module, must be created SEPARATELY/within an external/parent Terraform module:

1. An `aws_security_group` that the ElastiCache replication group will use for egress/ingress
2. An `aws_elasticache_subnet_group` that the ElastiCache replication group will use for multi-AZ availability

## Example

```hcl
module "redis_elasticache_app" {
  source = "github.com/18F/identity-terraform//redis_elasticache?ref=main"

  env_name                   = var.env_name
  app_name                   = "my-app"
  cluster_purpose            = "My Test App"
  node_type                  = var.elasticache_redis_app_node_type
  engine_version             = var.elasticache_redis_app_engine_version
  family_name                = var.elasticache_redis_app_family
  num_cache_clusters         = var.elasticache_redis_app_num_cache_clusters
  port                       = 6379
  security_group_ids         = [aws_security_group.elasticache_app.id]
  subnet_group_name          = aws_elasticache_subnet_group.app.name
  encrypt_at_rest            = var.elasticache_redis_app_encrypt_at_rest
  encrypt_in_transit         = var.elasticache_redis_app_encrypt_in_transit
  general_notification_arn   = local.elasticache_notification_arn
  cloudwatch_retention_days  = local.retention_days
  prevent_tf_log_deletion    = var.prevent_tf_log_deletion
  alarms_map                 = var.elasticache_redis_app_alarms_map
  high_alarm_action_arns     = local.moderate_priority_alarm_actions
  critical_alarm_action_arns = local.high_priority_alarm_actions
  period_duration            = 60
  runbook_url                = "https://example.com/wiki/Runbook:-Redis-alerts"
  threshold_network          = var.elasticache_redis_app_alarm_threshold_network
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
| <a name="module_alarms"></a> [alarms](#module\_alarms) | github.com/18F/identity-terraform//redis_alarms | 4c0ef9d94c3513423784e4a6d5e1d7584f2c3568 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.redis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_elasticache_parameter_group.redis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_parameter_group) | resource |
| [aws_elasticache_replication_group.redis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarms_map"></a> [alarms\_map](#input\_alarms\_map) | Map detailing the configuration for each simple metric alarm to create for the ElastiCache Redis cache cluster<br/>specified by var.cluster\_id below. Must follow the full format (keys/values) specified above; the 'default' value<br/>below can be used as an example for adding more alarms. | <pre>map(object({<br/>    alarm_name         = string<br/>    metric_name        = string<br/>    evaluation_periods = number<br/>    threshold_high     = string<br/>    threshold_critical = string<br/>    alarm_descriptor   = string<br/>  }))</pre> | <pre>{<br/>  "cpu": {<br/>    "alarm_descriptor": "CPU utilization",<br/>    "alarm_name": "CPU",<br/>    "evaluation_periods": 1,<br/>    "metric_name": "CPUUtilization",<br/>    "threshold_critical": 80,<br/>    "threshold_high": 70<br/>  },<br/>  "currconnections": {<br/>    "alarm_descriptor": "connections",<br/>    "alarm_name": "CurrConnections",<br/>    "evaluation_periods": 2,<br/>    "metric_name": "CurrConnections",<br/>    "threshold_critical": 50000,<br/>    "threshold_high": 40000<br/>  },<br/>  "memory": {<br/>    "alarm_descriptor": "memory utilization",<br/>    "alarm_name": "Memory",<br/>    "evaluation_periods": 1,<br/>    "metric_name": "DatabaseMemoryUsagePercentage",<br/>    "threshold_critical": 80,<br/>    "threshold_high": 75<br/>  },<br/>  "replication_lag": {<br/>    "alarm_descriptor": "replication lag",<br/>    "alarm_name": "ReplicationLag",<br/>    "evaluation_periods": 1,<br/>    "metric_name": "ReplicationLag",<br/>    "threshold_critical": ".2",<br/>    "threshold_high": ".1"<br/>  }<br/>}</pre> | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | String identifying the 'app' or purpose of the Redis cluster/replication group. Used in conjunction with var.env\_name<br/>unless var.cluster\_id\_override is set. MUST be specified if var.cluster\_id\_override is NOT specified. | `string` | `""` | no |
| <a name="input_cloudwatch_retention_days"></a> [cloudwatch\_retention\_days](#input\_cloudwatch\_retention\_days) | Number of days to retain Streams for all CloudWatch Log Groups defined in/created by this module. | `number` | `365` | no |
| <a name="input_cluster_id_override"></a> [cluster\_id\_override](#input\_cluster\_id\_override) | String used as full name/identifier for the Redis cluster/replication group.<br/>Will default to using var.env\_name-var.app\_name if not specified. | `string` | `""` | no |
| <a name="input_cluster_purpose"></a> [cluster\_purpose](#input\_cluster\_purpose) | Longer-string identifier for the aws\_elasticache\_replication\_group, used in the description. | `string` | n/a | yes |
| <a name="input_critical_alarm_action_arns"></a> [critical\_alarm\_action\_arns](#input\_critical\_alarm\_action\_arns) | List of actions to execute when 'critical' alarms transition into an ALARM state from any other state. | `list(string)` | n/a | yes |
| <a name="input_encrypt_at_rest"></a> [encrypt\_at\_rest](#input\_encrypt\_at\_rest) | Whether or not to enable encryption at rest. | `bool` | `true` | no |
| <a name="input_encrypt_in_transit"></a> [encrypt\_in\_transit](#input\_encrypt\_in\_transit) | Whether or not to enable encryption in transit. | `bool` | `true` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Version number of the cache engine to be used for the cache clusters in the replication group.<br/>Must specify both major AND minor version, which is a requirement by default if the version is 7 or higher. | `string` | `"7.1"` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | String identifying the environment where the Redis cluster is being created. Used in conjunction with var.app\_name<br/>unless var.cluster\_id\_override is set. MUST be specified if var.cluster\_id\_override is NOT specified. | `string` | `""` | no |
| <a name="input_family_name"></a> [family\_name](#input\_family\_name) | ElastiCache parameter group family. Must coincide with the value specified by var.engine\_version. | `string` | `"redis7"` | no |
| <a name="input_general_notification_arn"></a> [general\_notification\_arn](#input\_general\_notification\_arn) | (OPTIONAL) ARN of an SNS topic to send ElastiCache notifications to. | `string` | `""` | no |
| <a name="input_high_alarm_action_arns"></a> [high\_alarm\_action\_arns](#input\_high\_alarm\_action\_arns) | List of actions to execute when 'high' alarms transition into an ALARM state from any other state. | `list(string)` | n/a | yes |
| <a name="input_log_group_override"></a> [log\_group\_override](#input\_log\_group\_override) | Specific name of the CloudWatch Log Group used by the Redis cluster/replication group.<br/>Will use elasticache-var.env\_name-redis if no value is specified for this var. | `string` | `""` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | Type of node used by the Redis cluster, i.e. EC2 instance type WITH 'cache.' prefix. MUST point to an EC2<br/>instance/node type that has a NetworkPerformance value of 'Up to 5 Gigabit' or higher, or the threshold<br/>calculations for the 'redis\_network' CloudWatch metric alarm cannot be set properly. | `string` | n/a | yes |
| <a name="input_num_cache_clusters"></a> [num\_cache\_clusters](#input\_num\_cache\_clusters) | Number of cache clusters to create in the replication group. | `number` | `2` | no |
| <a name="input_period_duration"></a> [period\_duration](#input\_period\_duration) | Duration (in seconds) per evaluation period, for 'high' and 'critical' alarms. | `number` | `60` | no |
| <a name="input_port"></a> [port](#input\_port) | Port number for the Redis cluster/replication group. | `number` | `6379` | no |
| <a name="input_prevent_tf_log_deletion"></a> [prevent\_tf\_log\_deletion](#input\_prevent\_tf\_log\_deletion) | Whether or not to stop Terraform from ACTUALLY destroying CloudWatch Log Groups defined in/created by this module<br/>(vs. simply removing from state) upon marking the resource for deletion. | `bool` | `true` | no |
| <a name="input_runbook_url"></a> [runbook\_url](#input\_runbook\_url) | Link to a runbook to include in the alert description. | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of Security Group(s) to be used for access with the Redis cluster/replication group. Must be EXTERNALLY CREATED.<br/>Values must each follow correct Security Group identifier syntax, i.e. sg-0123abcd / sg-0123456789abcdef0 | `list(string)` | n/a | yes |
| <a name="input_subnet_group_name"></a> [subnet\_group\_name](#input\_subnet\_group\_name) | Externally-created ElastiCache subnet group, i.e. aws\_elasticache\_subnet\_group in Terraform. | `string` | n/a | yes |
| <a name="input_threshold_network"></a> [threshold\_network](#input\_threshold\_network) | Network utilization % used as threshold for the 'redis\_network' resource. | `number` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_log_group"></a> [log\_group](#output\_log\_group) | Name of the CloudWatch Log Group used by the replication group |
| <a name="output_member_clusters"></a> [member\_clusters](#output\_member\_clusters) | IDs of cache clusters in Redis replication group |
<!-- END_TF_DOCS -->