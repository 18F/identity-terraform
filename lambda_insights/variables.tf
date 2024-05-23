variable "region" {
  default     = "us-west-2"
  description = "Target AWS Region"
  type        = string
}

variable "lambda_insights_account" {
  default     = "580247275435"
  description = "The lambda insights account provided by AWS for monitoring"
  type        = string
}

variable "lambda_insights_version" {
  default     = 52
  description = "The lambda insights layer version to use for monitoring"
  type        = number
}
