variable "env_name" {
  description = "Environment name"
}

variable "region" {
  default     = "us-west-2"
  description = "AWS Region"
}

variable "kmslogging_service_enabled" {
  default     = 0
  description = "Enable KMS Logging service.  If disabled the CloudWatch rule will not be created."
}

variable "kinesis_shard_count" {
  default     = 1
  description = "Number of shards to allocate to Kinesis data stream"
}

variable "kinesis_retention_hours" {
  default     = 24
  description = "Number of hours to retain data in Kinesis data stream.  Max = 168"
}

# this filter will parse and only send log events that have
# an encryption context of pii-encryption or password-digest
variable "cloudwatch_filter_pattern" {
  default     = "[type, datetime, info, whitespace, (json = *decrypt* && json = *pii-encryption*) || (json = *decrypt* && json = *password-digest*)]"
  description = "Filter pattern for CloudWatch kms.log file"
}

variable "ct_queue_delay_seconds" {
  default     = 60
  description = "Number of seconds after the message is placed on the queue before it is able to be received"
}

variable "ct_queue_max_message_size" {
  default     = 2048
  description = "Max message size in kb"
}

variable "ct_queue_visibility_timeout_seconds" {
  default     = 120
  description = "Number of seconds that a received message is not visible to other workers"
}

variable "ct_queue_message_retention_seconds" {
  default     = 345600 # 4 days
  description = "Number of seconds a message will remain in the queue"
}

variable "ct_queue_maxreceivecount" {
  default     = 10
  description = "Number of times a message will be received before going to the deadletter queue"
}

variable "sns_topic_dead_letter_arn" {
  description = "SNS topic ARN for dead letter queue"
}

variable "lambda_identity_lambda_functions_gitrev" {
  default     = "40a8d2e68705313599e972a1cf50fd5a897ecc45"
  description = "Initial gitrev of identity-lambda-functions to deploy (updated outside of terraform)"
}

variable "dynamodb_retention_days" {
  default     = "365"
  description = "Number of days to retain kms log records in dynamodb"
}

variable "kmslog_lambda_debug" {
  default     = 0
  description = "Whether to run the kms logging lambdas in debug mode in this account"
}

variable "ec2_kms_arns" {
  default     = []
  description = "ARN(s) of EC2 roles permitted access to KMS"
}
