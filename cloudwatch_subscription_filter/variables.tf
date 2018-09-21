variable "env_name" {
    description = "Environment name"
}

variable "filter_name" {
    description = "Subscription filter name."
}

variable "cloudwatch_log_group_name" {
    description = "CloudWatch log group name that will be streamed to Kinesis."
}

variable "cloudwatch_filter_pattern" {
    description = "Filter pattern for CloudWatch subscription"
    default = "{$.id = *}"
}

variable "kinesis_stream_destination_arn" {
    description = "Kinesis stream destination arn"
}