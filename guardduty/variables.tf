variable "region" {
  type        = string
  description = "AWS Region for the module."
  default     = "us-west-2"
}

variable "enabled_features" {
  type        = map(list(string))
  description = <<EOM
Map of GuardDuty Features to set to ENABLED for the aws_guardduty_detector.main resource.
Each item should include the feature name (i.e. RDS_LOGIN_EVENTS, EKS_AUDIT_LOGS),
and (if any exist/are desired) any additional_configuration options for said feature.
Please note that EKS_RUNTIME_MONITORING and RUNTIME_MONITORING cannot BOTH be enabled
in the same detector, as (per AWS docs) attempting to do so will cause an error.
EOM
  default = {
    #"EBS_MALWARE_PROTECTION" = [],
    #"EKS_AUDIT_LOGS"         = [],
    #"EKS_RUNTIME_MONITORING" = [
    #  "EKS_ADDON_MANAGEMENT"
    #],
    #"LAMBDA_NETWORK_LOGS"    = [],
    #"RDS_LOGIN_EVENTS" = [
    #  "RDS_DATA_RISK"
    #],
    #"RUNTIME_MONITORING" = [
    #  "EKS_ADDON_MANAGEMENT",
    #  "ECS_FARGATE_AGENT_MANAGEMENT",
    #  "EC2_AGENT_MANAGEMENT"
    #],
    #"S3_DATA_EVENTS"         = [],
  }

  validation {
    condition = length([
      for feature in keys(var.enabled_features) : true if contains(
        ["RUNTIME_MONITORING", "EKS_RUNTIME_MONITORING"], feature
      )
    ]) < 2
    error_message = "Cannot enable both RUNTIME_MONITORING and EKS_RUNTIME_MONITORING; select one or the other."
  }
}

variable "bucket_name" {
  type        = string
  description = <<EOM
Second substring in S3 bucket name of
$bucket_name_prefix.$bucket_name.$account_id-$region.
EOM
  default     = "guardduty"
}

variable "bucket_name_prefix" {
  type        = string
  description = <<EOM
First substring in S3 bucket name of
$bucket_name_prefix.$bucket_name.$account_id-$region.
EOM
}

variable "bucket_name_override" {
  type        = string
  description = "Set this to override the normal bucket naming schema."
  default     = ""
}

variable "inventory_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket used for collecting S3 Inventory reports."
}

variable "logging_bucket_id" {
  type        = string
  description = "ID (name) of the S3 bucket used for logging S3 access events."
}

variable "s3_bucket_key_enabled" {
  type        = bool
  description = "Whether or not to use a Bucket Key for the S3 bucket(s) in this module."
  default     = false
}

variable "s3_blocked_encryption_types" {
  type        = list(string)
  description = "Single-item list of SSE types to block for object uploads to the S3 bucket(s) in this module."
  default = [
    "SSE-C"
  ]

  validation {
    condition     = contains(["NONE", "SSE-C"], var.s3_blocked_encryption_types[0])
    error_message = "var.s3_blocked_encryption_types must be set to 'NONE' or 'SSE-C'."
  }
}

variable "finding_freq" {
  type        = string
  description = "Frequency of notifications for GuardDuty findings."
  default     = "SIX_HOURS"
}

variable "cloudwatch_name" {
  type        = string
  description = "Name for the GuardDuty Findings CloudWatch Target/Event/Rule."
  default     = "GuardDutyFindings"
}

variable "log_group_id" {
  type        = string
  description = "ID of the CloudWatch Log Group to log GuardDuty findings."
  default     = "/aws/events/gdfindings"
}

variable "event_target_id" {
  type        = string
  description = "ID for the Event Target used for CloudWatch Logs."
  default     = "SendToCWLogGroup"
}

variable "publishing_policy_name" {
  type        = string
  description = "Name of the CloudWatch Log Resource Policy used for log delivery."
  default     = "cw-rule-log-publishing-policy"
}
