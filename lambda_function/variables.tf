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
  description = "Lambda handler functionn name"
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
  description = "Environment variable for the Lambda function"
  type        = map(any)
}

variable "log_retention_in_days" {
  description = "How long to retain log files"
  type        = number
}

variable "log_skip_destroy" {
  description = "Skip log destruction"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "ARNs for Cloudwatch Alarm actions"
  type        = list(any)
}

variable "insights_enabled" {
  description = ""
  default     = 1
  type        = number
}

variable "treat_missing_data" {
  default = "nonBreaching"
  type    = string
}

variable "cloudwatch_retention_days" {
  default = 30
  type    = number
}

variable "layers" {
  default     = []
  type        = list(any)
  description = "List of layers for the lambda function"
}

variable "iam_permissions" {
  default     = []
  type        = list(any)
  description = "List of IAM permissions for the lambda function"
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
