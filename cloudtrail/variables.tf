## basic CloudTrail settings

variable "trail_name" {
  type        = string
  description = "Name of the CloudTrail trail."
}

variable "enable_log_file_validation" {
  type        = bool
  description = "Whether log file integrity validation is enabled for the aws_cloudtrail.main resource."
  default     = true
}

variable "enable_logging" {
  type        = bool
  description = "Whether or not to enable logging for the aws_cloudtrail.main resource."
  default     = true
}

variable "include_global_service_events" {
  type        = bool
  description = "Whether the aws_cloudtrail.main resource is publishing events from global services (e.g. IAM) to logs."
  default     = false
}

variable "is_multi_region_trail" {
  type        = bool
  description = "Whether the aws_cloudtrail.main resource is created in the current region or in all regions."
  default     = false
}

variable "is_organization_trail" {
  type        = bool
  description = <<EOM
Whether the aws_cloudtrail.main resource is an AWS Organizations trail.
Can ONLY be created / set to 'true' in the master account for an organization.
EOM
  default     = false
}

## Event Selectors (use basic OR advanced, cannot use both!)

variable "basic_event_selectors" {
  type = list(object({
    include_management_events = bool
    read_write_type           = string
    excluded_sources          = optional(list(string))
    data_resources            = map(list(string))
  }))
  description = <<EOM
Map containing data on basic event selectors to configure for the aws_cloudtrail.main resource.
CANNOT be used in combination with var.advanced_event_selectors; only one may be selected.
Refer to commented-out default for an example of the structure to use.
EOM
  default     = []

  validation {
    condition = anytrue([
      length(var.advanced_event_selectors) == 0,
      length(var.basic_event_selectors) == 0
    ])
    error_message = "Cannot specify both basic_event_selectors and advanced_event_selectors"
  }
}

variable "advanced_event_selectors" {
  type = list(object({
    name          = string
    category      = string
    read_only     = optional(bool)
    error_code    = optional(string)
    resource_type = optional(string)
    fields = optional(map(object({
      equals          = optional(list(string))
      not_equals      = optional(list(string))
      ends_with       = optional(list(string))
      not_ends_with   = optional(list(string))
      not_starts_with = optional(list(string))
      starts_with     = optional(list(string))
    })))
  }))

  description = <<EOM
Map containing data on advanced event selectors to configure for the aws_cloudtrail.main resource.
CANNOT be used in combination with var.basic_event_selectors; only one may be selected.
Refer to commented-out defaults for an example of the structure to use.
EOM
  default     = []
}

## KMS

variable "kms_deletion_window" {
  type        = number
  description = "Waiting period (days) before aws_kms_key.cloudtrail is deleted, if ScheduleKeyDeletion is performed."
  default     = 7
}

variable "kms_enable_rotation" {
  type        = bool
  description = "Whether or not to enable automatic rotation of the aws_kms_key.cloudtrail resource."
  default     = true
}

variable "kms_regions" {
  type        = list(string)
  description = "List of regions to create replica KMS keys for the aws_kms_key.cloudtrail resource."
  default     = []
}

variable "kms_rotation_period" {
  type        = number
  description = "Period of time (days) between key rotations of the aws_kms_key.cloudtrail resource."
  default     = 90
}

## S3

variable "s3_bucket_key_enabled" {
  type        = bool
  description = "Whether or not to use aws_kms_key.cloudtrail as the S3 Bucket Key for aws_s3_bucket.cloudtrail"
  default     = false
}

variable "s3_force_destroy" {
  type        = bool
  description = "Allow destruction of aws_s3_bucket.cloudtrail bucket even if is not empty."
  default     = false
}

variable "s3_sse_algorithm" {
  type        = string
  description = "SSE encryption algorithm used with the aws_s3_bucket.cloudtrail S3 bucket."
  default     = "AES256"
}

variable "inventory_bucket_arn" {
  description = "ARN of the S3 bucket used for collecting the S3 Inventory reports."
  type        = string
}

variable "logging_bucket_id" {
  description = "Id of the S3 bucket used for collecting the S3 access events"
  type        = string
}

## CloudWatch

variable "cloudwatch_retention_days" {
  description = "Number of days to retain Streams for all CloudWatch Log Groups defined in/created by this module."
  type        = number
  default     = 365
}

variable "prevent_tf_log_deletion" {
  type        = bool
  description = <<EOM
Whether to ACTUALLY destroy CloudWatch Log Groups in this module vs. just removing them from state when using -destroy.
EOM
  default     = false
}
