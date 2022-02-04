variable "name" {
  description = "Unique name to use for resources"
  type        = string
  default     = "cloudwatch_sli"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.8"
}

variable "window_days" {
  description = "SLI window in days"
  type        = number
  default     = 24
}

variable "sli_namespace" {
  description = "CloudWatch namespace in which to insert the SLI metric"
  type        = string
  default     = "prod/sli"
}

variable "load_balancer_arn" {
  description = "ID of ALB"
  type        = string
}

variable "sli_prefix" {
  description = "Prefix for SLI metric names"
  type        = string
  default     = "test"
}
