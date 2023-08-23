variable "env_name" {
  description = "Environment name"
}

variable "region" {
  default     = "us-west-2"
  description = "AWS Region"
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
  default     = "1815de9b0893548876138e7086391e210cc85813"
  description = "Initial gitrev of identity-lambda-functions to deploy (updated outside of terraform)"
}

variable "dynamodb_retention_days" {
  default     = 365
  description = "Number of days to retain kms log records in dynamodb"
}

variable "kmslog_lambda_debug" {
  default     = false
  description = "Whether to run the kms logging lambdas in debug mode in this account"
  type        = bool
}

variable "kmslog_lambda_dry_run" {
  default     = false
  description = "Whether to run the kms logging lambdas in dry run mode in this account"
  type        = bool
}

variable "ec2_kms_arns" {
  default     = []
  description = "ARN(s) of EC2 roles permitted access to KMS"
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS Topic ARN for alarms"
  type        = list(string)
  default     = []
}

## Lambda KMS CloudWatch Processor Configuration

variable "lambda_kms_cw_processor_zip" {
  description = "Lambda zip file providing source code for kms cloudwatch processor"
  type        = string
}

variable "cw_processor_memory_size" {
  description = "Defines the amount of memory in MB the CloudWatch Processor can use at runtime"
  type        = number
  default     = 128
  validation {
    condition     = var.cw_processor_memory_size >= 128 && var.cw_processor_memory_size <= 10240
    error_message = "The cw_processor_memory_size must be between the values 512 MB and 10240 MB"
  }
}

variable "cw_processor_storage_size" {
  description = "Defines the amount of ephemeral storage (/tmp) in MB available to the CloudWatch Processor"
  type        = number
  default     = 512
  validation {
    condition     = var.cw_processor_storage_size >= 512 && var.cw_processor_storage_size <= 10240
    error_message = "The cw_processor_storage_size must be between the values 512 MB and 10240 MB"
  }
}

## Lambda KMS Cloudtrail Processor Configuration

variable "lambda_kms_ct_processor_zip" {
  description = "Lambda zip file providing source code for kms cloudtrail processor"
  type        = string
}

## Lambda KMS Event Processor Configuration

variable "lambda_kms_event_processor_zip" {
  description = "Lambda zip file providing source code for kms event processor"
  type        = string
}

## Lambda KMS Slack Batch Processor Configuration

variable "lambda_slack_batch_processor_zip" {
  description = "Lambda source code that batches KMS events for notification"
  type        = string
}
