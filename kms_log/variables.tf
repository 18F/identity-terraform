## Locals

locals {
  lambda_insights_arn = join(":", [
    "arn:aws:lambda:${var.region}:${var.lambda_insights_account}:layer",
    "LambdaInsightsExtension:${var.lambda_insights_version}"
  ])

  kinesis_stream_name         = "${var.env_name}-kms-app-events"
  ct_processor_lambda_name    = "${var.env_name}-cloudtrail-kms"
  ct_requeue_lambda_name      = "${var.env_name}-kms-cloudtrail-requeue"
  cw_processor_lambda_name    = "${var.env_name}-cloudwatch-kms"
  event_processor_lambda_name = "${var.env_name}-kmslog-event-processor"
  slack_processor_lambda_name = "${var.env_name}-kms-slack-batch-processor"
}

## Variables

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
  default     = "{ ($.kms.action = \"decrypt\" && $.kms.encryption_context.context = %password-digest+|pii-encryption+% ) }"
  description = "Filter pattern for CloudWatch kms.log file"
}

variable "ct_queue_delay_seconds" {
  default     = 60
  description = "Number of seconds after the message is placed on the queue before it is able to be received"
}

variable "ct_queue_max_message_size" {
  default     = 4096
  description = "Max message size in bytes"
  type        = number
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

variable "max_skew_seconds" {
  default     = 8
  description = "Number of seconds before/after timestamp to search for matches"
  type        = number
}

variable "ec2_kms_arns" {
  default     = []
  description = "ARN(s) of EC2 roles permitted access to KMS"
}

variable "alarm_sns_topic_arns" {
  default     = []
  description = "List of SNS Topic ARN for alarms"
  type        = list(string)
}

variable "kinesis_source_log_group" {
  description = "The source log group the kinesis stream will consume events from"
  type        = string
}

variable "lambda_insights_account" {
  default     = "580247275435"
  description = "The lambda insights account provided by AWS for monitoring"
  type        = string
}

variable "lambda_insights_version" {
  default     = 38
  description = "The lambda insights layer version to use for monitoring"
  type        = number
}

variable "cloudwatch_retention_days" {
  default     = 90
  description = "Number of days to retain CloudWatch Logs for Lambda functions"
  type        = number
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

## Lambda KMS Cloudtrail Requeue Configuration

variable "lambda_kms_ct_requeue_zip" {
  description = "Lambda zip file providing source code for kms cloudtrail requeue service"
  type        = string
}

variable "ct_requeue_concurrency" {
  description = "Defines the number of concurrent requeue lambda executions"
  type        = number
  default     = 1
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

variable "sqs_alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the sqs alarms fire"
}

variable "sqs_ok_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the sqs alarms return to an OK state"
}

