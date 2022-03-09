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
  default     = "python3.8"
}

variable "slo_lambda_code" {
  type        = string
  description = "Path of the compressed lambda source code."
  default     = "src/windowed_slo.zip"
}

variable "window_days" {
  description = "SLI window in days"
  type        = number
  default     = 24
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
