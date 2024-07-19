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
  description = "Lambda handler functionn ame"
  type        = string
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
}

variable "runtime" {
  description = "Lambda function runtime"
  type        = string
}

variable "timeout" {
  description = "Lambda timeout"
  type        = number
}

variable "environment_variables" {
  description = "Environment variable for the Lambda function"
  type        = map(any)
}

variable "role" {
  description = "Lambda function IAM role"
  type        = string
}

variable "log_retention_in_days" {
  description = "How long to retain log files"
  type        = number
}

variable "log_skip_destroy" {
  description = "Skip log destruction"
  type        = bool
}

variable "alarm_actions" {
  description = "ARNs for Cloudwatch Alarm actions"
  type        = string
}

variable "insights_enabled" {
  description = ""
  default     = true
  type        = bool
}

variable "treat_missing_data" {
  default = "nonBreaching"
  type    = string
}

