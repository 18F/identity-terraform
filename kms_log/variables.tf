## Locals

locals {
  lambda_insights_arn = join(":", [
    "arn:aws:lambda:${var.region}:${var.lambda_insights_account}:layer",
    "LambdaInsightsExtension:${var.lambda_insights_version}"
  ])

  ct_processor_lambda_name    = "${var.env_name}-cloudtrail-kms"
  ct_requeue_lambda_name      = "${var.env_name}-kms-cloudtrail-requeue"
  cw_processor_lambda_name    = "${var.env_name}-cloudwatch-kms"
  event_processor_lambda_name = "${var.env_name}-kmslog-event-processor"
  slack_processor_lambda_name = "${var.env_name}-kms-slack-batch-processor"
}

## Variables

variable "env_name" {
  type        = string
  description = "Environment name"
}

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-west-2"
}

variable "kinesis_shard_count" {
  type        = number
  description = "Number of shards to allocate to Kinesis data stream"
  default     = 1
}

variable "kinesis_retention_hours" {
  type        = number
  description = "Number of hours to retain data in Kinesis data stream.  Max = 168"
  default     = 24
}

# this filter will parse and only send log events that have
# an encryption context of pii-encryption or password-digest
variable "cloudwatch_filter_pattern" {
  type        = string
  description = "Filter pattern for CloudWatch kms.log file"
  default     = "{ ($.kms.action = \"decrypt\" && $.kms.encryption_context.context = %password-digest+|pii-encryption+% ) }"
}

variable "ct_queue_delay_seconds" {
  type        = number
  description = "Number of seconds after the message is placed on the queue before it is able to be received"
  default     = 60
}

variable "ct_queue_max_message_size" {
  type        = number
  description = "Max message size in bytes"
  default     = 4096
}

variable "ct_queue_visibility_timeout_seconds" {
  type        = number
  description = "Number of seconds that a received message is not visible to other workers"
  default     = 120
}

variable "ct_queue_message_retention_seconds" {
  type        = number
  description = "Number of seconds a message will remain in the queue"
  default     = 345600 # 4 days
}

variable "ct_queue_maxreceivecount" {
  type        = number
  description = "Number of times a message will be received before going to the deadletter queue"
  default     = 10
}

variable "dynamodb_retention_days" {
  type        = number
  description = "Number of days to retain kms log records in dynamodb"
  default     = 365
}

variable "kmslog_lambda_debug" {
  type        = bool
  description = "Whether to run the kms logging lambdas in debug mode in this account"
  default     = false
}

variable "kmslog_lambda_dry_run" {
  type        = bool
  description = "Whether to run the kms logging lambdas in dry run mode in this account"
  default     = false
}

variable "ct_processor_max_skew_seconds" {
  type        = number
  description = "Number of seconds before/after timestamp to search for matches"
  default     = 8
}

variable "ec2_kms_arns" {
  type        = list(string)
  description = "ARN(s) of EC2 roles permitted access to KMS"
  default     = []
}

variable "alarm_sns_topic_arns" {
  type        = list(string)
  description = "List of SNS Topic ARN for alarms"
  default     = []
}

variable "kinesis_source_log_group" {
  type        = string
  description = "The source log group the kinesis stream will consume events from"
}

variable "lambda_insights_account" {
  type        = string
  description = "The lambda insights account provided by AWS for monitoring"
  default     = "580247275435"
}

variable "lambda_insights_version" {
  type        = number
  description = "The lambda insights layer version to use for monitoring"
  default     = 38
}

variable "cloudwatch_retention_days" {
  type        = number
  description = "Number of days to retain CloudWatch Logs for Lambda functions"
  default     = 90
}

## Lambda KMS CloudWatch Processor Configuration

variable "lambda_kms_cw_processor_zip" {
  type        = string
  description = "Lambda zip file providing source code for kms cloudwatch processor"
}

variable "lambda_kms_cw_processor_zip_base64sha256" {
  description = "base64-encoded SHA256 checksum of lambda_kms_cw_processor_zip file"
  type        = string
}

variable "cw_processor_memory_size" {
  type        = number
  description = "Defines the amount of memory in MB the CloudWatch Processor can use at runtime"
  default     = 128
  validation {
    condition     = var.cw_processor_memory_size >= 128 && var.cw_processor_memory_size <= 10240
    error_message = "The cw_processor_memory_size must be between the values 512 MB and 10240 MB"
  }
}

variable "cw_processor_storage_size" {
  type        = number
  description = "Defines the amount of ephemeral storage (/tmp) in MB available to the CloudWatch Processor"
  default     = 512
  validation {
    condition     = var.cw_processor_storage_size >= 512 && var.cw_processor_storage_size <= 10240
    error_message = "The cw_processor_storage_size must be between the values 512 MB and 10240 MB"
  }
}

## Lambda KMS Cloudtrail Processor Configuration

variable "lambda_kms_ct_processor_zip" {
  type        = string
  description = "Lambda zip file providing source code for kms cloudtrail processor"
}

variable "lambda_kms_ct_processor_zip_base64sha256" {
  description = "base64-encoded SHA256 checksum of lambda_kms_ct_processor_zip file"
  type        = string
}

## Lambda KMS Cloudtrail Requeue Configuration

variable "lambda_kms_ct_requeue_zip" {
  type        = string
  description = "Lambda zip file providing source code for kms cloudtrail requeue service"
}

variable "lambda_kms_ct_requeue_zip_base64sha256" {
  description = "base64-encoded SHA256 checksum of lambda_kms_ct_requeue_zip file"
  type        = string
}

variable "ct_requeue_concurrency" {
  type        = number
  description = "Defines the number of concurrent requeue lambda executions"
  default     = 1
}

## Lambda KMS Event Processor Configuration

variable "lambda_kms_event_processor_zip" {
  type        = string
  description = "Lambda zip file providing source code for kms event processor"
}

variable "lambda_kms_event_processor_zip_base64sha256" {
  description = "base64-encoded SHA256 checksum of lambda_kms_event_processor_zip file"
  type        = string
}

## Lambda KMS Slack Batch Processor Configuration

variable "lambda_slack_batch_processor_zip" {
  type        = string
  description = "Lambda source code that batches KMS events for notification"
}

variable "lambda_slack_batch_processor_zip_base64sha256" {
  description = "base64-encoded SHA256 checksum of lambda_slack_batch_processor_zip file"
  type        = string
}

variable "sqs_alarm_actions" {
  description = "A list of ARNs to notify when the sqs alarms fire"
  type        = list(string)
}

variable "sqs_ok_actions" {
  description = "A list of ARNs to notify when the sqs alarms return to an OK state"
  type        = list(string)
}
