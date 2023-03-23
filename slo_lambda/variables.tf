locals {
  name = "${var.env_name}-cloudwatch-sli"
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "slo_lambda_code" {
  type        = string
  description = "Filename of the compressed lambda source code."
  default     = "windowed_slo.zip"
}

variable "window_days" {
  description = "Global SLI window in days. A four-week window is a good general-purpose interval, based on https://sre.google/workbook/implementing-slos/"
  type        = number
  default     = 28
}

variable "namespace" {
  description = <<EOM
Manually-specified CloudWatch namespace in which to insert the SLI metric
(defaults to env_name/sli if not set)
EOM
  type        = string
  default     = ""
}

variable "load_balancer_arn" {
  description = "ID of ALB"
  type        = string
}

variable "sli_prefix" {
  description = "Prefix for SLI metric names, commonly the source, e.g. idp, gitlab."
  type        = string
  default     = "idp"
}

variable "slis" {
  description = "SLI configuration"
  type = map(object({
    description = optional(string)
    window_days = optional(number)
    numerator = list(object({
      namespace          = string
      metric_name        = string
      dimensions         = list(map(string))
      statistic          = optional(string)
      extended_statistic = optional(string)
    }))
    denominator = list(object({
      namespace          = string
      metric_name        = string
      dimensions         = list(map(string))
      statistic          = optional(string)
      extended_statistic = optional(string)
    }))
  }))
}
