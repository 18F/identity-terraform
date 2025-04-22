variable "region" {
  default     = "us-west-2"
  description = ""
  type        = string
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Full Lambda handler string"
  type        = string
  default     = ""
}

variable "handler_function_name" {
  description = "Lambda handler function name"
  type        = string
  default     = "lambda_handler"
}

variable "source_code_filename" {
  description = "Name of the file containing the Lambda source code"
  type        = string
}

variable "source_dir" {
  description = "Directory containing the Lambda source code"
  type        = string
}

variable "memory_size" {
  description = "Memory allocated to the Lambda function"
  type        = string
  default     = "128"
}

variable "runtime" {
  description = "Lambda function runtime"
  type        = string
}

variable "timeout" {
  description = "Lambda timeout"
  type        = number
  default     = 120
}

variable "environment_variables" {
  description = <<EOM
  Environment variables for the Lambda function. Individual variables must be
  of a type that terraform can convert to strings. Lists and maps must be
  `jsonencode`ed.
  EOM
  type        = map(any)
}

variable "reserved_concurrent_executions" {
  description = "The max number concurrent invocations allowed for the Lambda"
  default     = -1
}
variable "role_name_prefix" {
  default     = null
  description = <<EOM
Prefix string used to specify the name of the function's IAM role.
Required if creating the same function in multiple regions.
If not specified, will set the role name to the value of  
var.lambda_iam_role_name or the default of '{var.function_name}-lambda-role'
EOM
  type        = string
}

variable "log_skip_destroy" {
  description = "Skip log destruction"
  type        = bool
  default     = false
}

variable "cloudwatch_retention_days" {
  default = 2192
  type    = number
}

variable "layers" {
  default     = []
  type        = list(any)
  description = "List of layers for the lambda function"
}

variable "lambda_iam_policy_document" {
  default     = ""
  type        = string
  description = "IAM permissions for the lambda function. Use a data.aws_iam_policy_document to construct"
}

variable "lambda_iam_role_name" {
  default     = null
  type        = string
  description = <<EOM
Role name override for resources that need underscores.
If not specified, will set the role name to the default of '{var.function_name}-lambda-role'
If var.role_name_prefix is set, the module will use the name prefix instead of the role name
EOM
}

variable "iam_role_description" {
  default     = ""
  description = "Description of the iam role associated with the lambda function"
  type        = string
}

variable "schedule_expression" {
  default     = ""
  description = "Cron or rate expression to trigger lambda"
  type        = string
}

variable "event_pattern" {
  default     = ""
  description = "EventBridge pattern to trigger lambda"
  type        = string
}

# All of the variables below are utilized by the lambda alerts module.
variable "enabled" {
  type        = number
  description = "Whether or not to create the Lambda alert monitor."
  default     = 1
}

variable "env_name" {
  type        = string
  description = "Name of the environment in which the lambda function lives"
  default     = ""
}

variable "alarm_actions" {
  description = "ARNs for Cloudwatch Alarm actions"
  type        = list(any)
}

variable "ok_actions" {
  description = "ARNs for Cloudwatch OK actions"
  type        = list(any)
  default     = []
}

variable "runbook" {
  type        = string
  description = "A link to a runbook associated with any metric in this module"
  default     = ""
}

variable "error_rate_operator" {
  type        = string
  description = "The operator used to compare a calculated error rate against a threshold"
  default     = "GreaterThanOrEqualToThreshold"
}

variable "error_rate_threshold" {
  type        = number
  description = "The threshold error rate (as a percentage) for triggering an alert"
  default     = 1
}

variable "memory_usage_threshold" {
  type        = number
  description = "The threshold memory utilization (as a percentage) for triggering an alert"
  default     = 90
}

variable "duration_threshold" {
  type        = number
  description = "The duration threshold (as a percentage) for triggering an alert"
  default     = 80
}

variable "datapoints_to_alarm" {
  type        = number
  description = "The number of datapoints that must be breaching to trigger the alarm."
  default     = 1
}

variable "evaluation_periods" {
  type    = number
  default = 1
}

variable "period" {
  type        = number
  description = "The period in seconds over which the specified statistic is applied."
  default     = 60
}

variable "treat_missing_data" {
  default = "notBreaching"
  type    = string
}

variable "insights_enabled" {
  description = "Whether the lambda has Lambda Insights enabled"
  default     = true
  type        = bool
}

variable "error_rate_alarm_name_override" {
  type        = string
  description = "Overrides the default alarm naming convention with a custom name"
  default     = ""
}
variable "memory_usage_alarm_name_override" {
  type        = string
  description = "Overrides the default alarm naming convention with a custom name"
  default     = ""
}
variable "duration_alarm_name_override" {
  type        = string
  description = "Overrides the default alarm naming convention with a custom name"
  default     = ""
}

variable "error_rate_alarm_description" {
  type        = string
  description = "Overrides the default alarm description for error rate alarm"
  default     = ""
}

variable "memory_usage_alarm_description" {
  type        = string
  description = "Overrides the default alarm description for memory usage alarm"
  default     = ""
}

variable "duration_alarm_description" {
  type        = string
  description = "Overrides the default alarm description for duration alarm"
  default     = ""
}