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

variable "log_skip_destroy" {
  description = "Skip log destruction"
  type        = bool
  default     = false
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

variable "insights_enabled" {
  description = "Whether the lambda has Lambda Insights enabled"
  default     = true
  type        = bool
}

variable "treat_missing_data" {
  default = "nonBreaching"
  type    = string
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
