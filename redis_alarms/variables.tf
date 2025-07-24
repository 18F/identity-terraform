variable "cluster_id" {
  type        = string
  description = "ID of the cache cluster that the alarms are created for."
}

variable "alarms_map" {
  type = map(object({
    alarm_name         = string
    metric_name        = string
    evaluation_periods = number
    threshold_high     = string
    threshold_critical = string
    alarm_descriptor   = string
  }))

  description = <<EOM
Map detailing the configuration for each simple metric alarm to create
for the ElastiCache Redis cache cluster specified by var.cluster_id below.
Must follow the full format (keys/values) specified above; the 'default'
value below can be used as an example for adding more alarms.
EOM

  default = {
    "memory" = {
      alarm_name         = "Memory"
      metric_name        = "DatabaseMemoryUsagePercentage"
      evaluation_periods = 1
      threshold_high     = 75
      threshold_critical = 80
      alarm_descriptor   = "memory utilization"
    }
    "cpu" = {
      alarm_name         = "CPU"
      metric_name        = "CPUUtilization"
      evaluation_periods = 1
      threshold_high     = 70
      threshold_critical = 80
      alarm_descriptor   = "CPU utilization"
    }
    "currconnections" = {
      alarm_name         = "CurrConnections"
      metric_name        = "CurrConnections"
      evaluation_periods = 2
      threshold_high     = 40000
      threshold_critical = 50000
      alarm_descriptor   = "connections"
    }
    "replication_lag" = {
      alarm_name         = "ReplicationLag"
      metric_name        = "ReplicationLag"
      evaluation_periods = 1
      threshold_high     = ".1"
      threshold_critical = ".2"
      alarm_descriptor   = "replication lag"
    }
  }
}

variable "high_alarm_action_arns" {
  type        = list(string)
  description = <<EOM
List of actions to execute when the 'high' alarms
transition into an ALARM state from any other state.
Each MUST be specified as an Amazon Resource Name (ARN).
EOM
  validation {
    condition = alltrue([
      for arn in var.high_alarm_action_arns : can(regex(
        "^arn:aws:[a-z0-9]+:\\w+(?:-\\w+)+:\\d{12}:[A-Za-z0-9]+(?:[-_\\:\\/\\.+=,@][A-Za-z0-9]+)+$", arn
      ))
    ])
    error_message = "All strings in list must be valid AWS ARNs."
  }
}

variable "critical_alarm_action_arns" {
  type        = list(string)
  description = <<EOM
List of actions to execute when the 'critical'/'network' alarms
transition into an ALARM state from any other state.
Each MUST be specified as an Amazon Resource Name (ARN).
EOM
  validation {
    condition = alltrue([
      for arn in var.critical_alarm_action_arns : can(regex(
        "^arn:aws:[a-z0-9]+:\\w+(?:-\\w+)+:\\d{12}:[A-Za-z0-9]+(?:[-_\\:\\/\\.+=,@][A-Za-z0-9]+)+$", arn
      ))
    ])
    error_message = "All strings in var.critical_alarm_action_arns must be valid AWS ARNs"
  }
}

variable "period_duration" {
  type        = number
  description = <<EOM
Duration (in seconds) per evaluation period, for 'high' and 'critical' alarms.
EOM
  default     = 60
}

variable "runbook_url" {
  type        = string
  description = "Link to a runbook to include in the alert description."
}

variable "node_type" {
  type        = string
  description = <<EOM
Type of node (specifically an EC2 instance type, i.e. WITHOUT 'cache.' prefix)
used by the Redis cache cluster. MUST point to an EC2 instance/node type that
has a NetworkPerformance value of 'Up to 5 Gigabit' or higher, or the threshold
calculations for the 'redis_network' resource cannot be set properly.
EOM
  validation {
    condition = can(regex(
      "^[cmrt][3-7](g[nd]*)*\\.(((2|4|8|10|12|16|24)*x)*large|medium|micro|small)$",
      var.node_type
    ))
    error_message = "Must be a valid EC2 instance type, WITHOUT the 'cache.' prefix."
  }
}

variable "threshold_network" {
  type        = number
  description = <<EOM
Percentage of network utilization (whole numbers only) used as threshold for
the 'redis_network' resource. Alarm will fire when this percentage is reached
at least 1 time in 60 seconds.
EOM
}
