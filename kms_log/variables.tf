variable "env_name" {
  description = "Environment name"
}

variable "region" {
  default = "us-west-2"
  description = "AWS Region"
}

variable "kmslogging_service_enabled" {
  default = 0
  description = "Enable KMS Logging service.  If disabled the CloudWatch rule will not be created."
}

variable "kinesis_shard_count" {
  default = 1
  description = "Number of shards to allocate to Kinesis data stream"
}

variable "kinesis_retention_hours" {
  default = 24
  description = "Number of hours to retain data in Kinesis data stream.  Max = 168"
}

# this filter will parse and only send log events that have
# an encryption context of pii-encryption or password-digest
variable "cloudwatch_filter_pattern" {
  default = "[type, datetime, info, whitespace, json = *pii-encryption* || json = *password-digest*]"
  description = "Filter pattern for CloudWatch kms.log file"
}

variable "ct_queue_delay_seconds" {
  default = 60
  description = "Number of seconds after the message is placed on the queue before it is able to be received"
}

variable "ct_queue_max_message_size" {
  default = 2048
  description = "Max message size in kb"
}

variable "ct_queue_visibility_timeout_seconds" {
  default = 60
  description = "Number of seconds that a received message is not visible to other workers"
}

variable "ct_queue_message_retention_seconds" {
  default = 345600 # 4 days
  description = "Number of seconds a message will remain in the queue"
}

variable "ct_queue_maxreceivecount" {
  default = 10
  description = "Number of times a message will be received before going to the deadletter queue"
}

variable "sns_topic_dead_letter" {
  description = "SNS topic name for dead letter queue"
  default = "identity-events"
}