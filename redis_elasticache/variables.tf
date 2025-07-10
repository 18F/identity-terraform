variable "env_name" {
  type        = string
  description = <<EOM
String identifying the environment where the Redis cluster is being created. Used in conjunction with var.app_name
unless var.cluster_id_override is set. MUST be specified if var.cluster_id_override is NOT specified.
EOM
  default     = ""

  validation {
    condition     = var.cluster_id_override == "" ? length(var.env_name) > 0 : true
    error_message = "Must specify var.app_name AND var.env_name if not using var.cluster_id_override"
  }
}

variable "app_name" {
  type        = string
  description = <<EOM
String identifying the 'app' or purpose of the Redis cluster/replication group. Used in conjunction with var.env_name
unless var.cluster_id_override is set. MUST be specified if var.cluster_id_override is NOT specified.
EOM
  default     = ""

  validation {
    condition     = var.cluster_id_override == "" ? length(var.app_name) > 0 : true
    error_message = "Must specify var.app_name AND var.env_name if not using var.cluster_id_override"
  }
}

variable "cluster_id_override" {
  type        = string
  description = <<EOM
String used as full name/identifier for the Redis cluster/replication group.
Will default to using var.env_name-var.app_name if not specified.
EOM
  default     = ""
}

variable "cluster_purpose" {
  type        = string
  description = "Longer-string identifier for the aws_elasticache_replication_group, used in the description."
}

variable "node_type" {
  type        = string
  description = <<EOM
Type of node used by the Redis cluster, i.e. EC2 instance type WITH 'cache.' prefix. MUST point to an EC2
instance/node type that has a NetworkPerformance value of 'Up to 5 Gigabit' or higher, or the threshold
calculations for the 'redis_network' CloudWatch metric alarm cannot be set properly.
EOM
  validation {
    condition = can(regex(
      "^cache\\.[cmrt][3-7](g[nd]*)*\\.(((2|4|8|10|12|16|24)*x)*large|medium|micro|small)$",
      var.node_type
    ))
    error_message = "Must be a valid EC2 instance type WITH the 'cache.' prefix."
  }
}

variable "engine_version" {
  type        = string
  description = <<EOM
Version number of the cache engine to be used for the cache clusters in the replication group.
Must specify both major AND minor version, which is a requirement by default if the version is 7 or higher.
EOM
  default     = "7.1"

  validation {
    condition = can(regex(
      "^[45]\\.[0-9]\\.[0-9]+|[67]\\.[0-9]+$",
      var.engine_version
    ))
    error_message = "Must be #.##.## for versions 4/5, or #.## for 6/7"
  }
}

variable "family_name" {
  type        = string
  description = "ElastiCache parameter group family. Must coincide with the value specified by var.engine_version."
  default     = "redis7"

  validation {
    condition = anytrue([
      length(regexall("^7\\.[0-9]+$", var.engine_version)) > 0 && var.family_name == "redis7",
      length(regexall("^6\\.[0-9]+$", var.engine_version)) > 0 && var.family_name == "redis6.x",
      length(regexall("^[45]\\.[0-9]\\.[0-9]+$", var.engine_version)) > 0 && (
        var.family_name == join("", ["redis", split(".", var.engine_version)[0]])
      )
    ])
    error_message = "Family name must coincide with var.engine_version"
  }
}

variable "group_parameters" {
  type        = list(map(string))
  description = <<EOM
List of ElastiCache parameters to provide override/customized values for, within the aws_elasticache_parameter_group
resource. Parameter group will be created with default values if nothing is specified for this variable.
EOM
  default = [
    #{
    #  "name" = "maxmemory-policy",
    #  "value" = "noeviction"
    #},
  ]
}

variable "num_cache_clusters" {
  type        = number
  description = "Number of cache clusters to create in the replication group."
  default     = 2
}

variable "port" {
  type        = number
  description = "Port number for the Redis cluster/replication group."
  default     = 6379
}

variable "security_group_ids" {
  type        = list(string)
  description = <<EOM
List of Security Group(s) to be used for access with the Redis cluster/replication group. Must be EXTERNALLY CREATED.
Values must each follow correct Security Group identifier syntax, i.e. sg-0123abcd / sg-0123456789abcdef0
EOM

  validation {
    condition = alltrue([
      for sg in var.security_group_ids : can(regex(
        "^sg-[0-9a-f]{8}([0-9a-f]{9})?$", sg
      ))
    ])
    error_message = "Must follow correct syntax, i.e. sg-0123abcd / sg-0123456789abcdef0"
  }
}

variable "subnet_group_name" {
  type        = string
  description = "Externally-created ElastiCache subnet group, i.e. aws_elasticache_subnet_group in Terraform."
}

variable "encrypt_at_rest" {
  type        = bool
  description = "Whether or not to enable encryption at rest."
  default     = true
}

variable "encrypt_in_transit" {
  type        = bool
  description = "Whether or not to enable encryption in transit."
  default     = true
}

variable "general_notification_arn" {
  type        = string
  description = "(OPTIONAL) ARN of an SNS topic to send ElastiCache notifications to."
  default     = null

  validation {
    condition = anytrue([
      var.general_notification_arn == null,
      can(regex(
        "^arn:aws:sns:\\w+(?:-\\w+)+:\\d{12}:[A-Za-z0-9]+(?:[-_\\/\\.+=,@][A-Za-z0-9]+)+$",
        var.general_notification_arn
      ))
    ])
    error_message = "Must be a valid ARN for AWS SNS, if specified."
  }
}

variable "external_cloudwatch_log_group" {
  type        = string
  description = <<EOM
Externally-created CloudWatch Log Group, to be used by the Redis cluster/replication group, if desired.
Set/specify only if wanting to NOT create/manage the aws_cloudwatch_log_group.redis resource within THIS module.
EOM
  default     = ""
}

variable "cloudwatch_retention_days" {
  description = "Number of days to retain Streams for all CloudWatch Log Groups defined in/created by this module."
  type        = number
  default     = 365
}

variable "prevent_tf_log_deletion" {
  description = <<EOM
Whether or not to stop Terraform from ACTUALLY destroying CloudWatch Log Groups defined in/created by this module
(vs. simply removing from state) upon marking the resource for deletion.
EOM
  type        = bool
  default     = true
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
Map detailing the configuration for each simple metric alarm to create for the ElastiCache Redis cache cluster
specified by var.cluster_id below. Must follow the full format (keys/values) specified above; the 'default' value
below can be used as an example for adding more alarms.
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
  description = "List of actions to execute when 'high' alarms transition into an ALARM state from any other state."

  validation {
    condition = alltrue([
      for arn in var.high_alarm_action_arns : can(regex(
        "^arn:aws:[a-z0-9]+:\\w+(?:-\\w+)+:\\d{12}:[A-Za-z0-9]+(?:[-_\\/\\.+=,@][A-Za-z0-9]+)+$", arn
      ))
    ])
    error_message = "All strings in list must be valid AWS ARNs."
  }
}

variable "critical_alarm_action_arns" {
  type        = list(string)
  description = "List of actions to execute when 'critical' alarms transition into an ALARM state from any other state."

  validation {
    condition = alltrue([
      for arn in var.critical_alarm_action_arns : can(regex(
        "^arn:aws:[a-z0-9]+:\\w+(?:-\\w+)+:\\d{12}:[A-Za-z0-9]+(?:[-_\\/\\.+=,@][A-Za-z0-9]+)+$", arn
      ))
    ])
    error_message = "All strings in var.critical_alarm_action_arns must be valid AWS ARNs"
  }
}

variable "period_duration" {
  type        = number
  description = "Duration (in seconds) per evaluation period, for 'high' and 'critical' alarms."
  default     = 60
}

variable "runbook_url" {
  type        = string
  description = "Link to a runbook to include in the alert description."
}

variable "threshold_network" {
  type        = number
  description = "Network utilization % used as threshold for the 'redis_network' resource."
}
