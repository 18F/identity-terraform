variable "enabled" {
  type        = bool
  default     = true
  description = "Enables the set of alerts defined in this module"
}

variable "queue_name" {
  type        = string
  description = "The name of the SQS queue to monitor"
}

variable "queue_type" {
  type        = string
  default     = "standard"
  description = "The type of SQS queue to monitor"

  validation {
    condition     = var.queue_type == "standard" || var.queue_type == "fifo"
    error_message = "The queue type value must be \"standard\" or \"fifo\""
  }
}

variable "inflight_threshold" {
  type        = number
  description = "The percentile threshold of inflight messages"
  default     = 80
}

variable "max_message_size" {
  type = number
  description = "The maximum message size supported by the queue"
}

variable "message_size_threshold" {
  type = number
  description = "The percentile threshold of message sizes"
  default = 80
}

variable "evaluation_periods" {
  type    = number
  default = 1
}

variable "period" {
  type        = number
  description = "The period in seconds over which the specified statistic is applied"
  default     = 60
}
