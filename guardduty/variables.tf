# Locals

locals {
  gd_perm_conditions = [
    {
      "variable" = "aws:SourceAccount",
      "values"   = [data.aws_caller_identity.current.account_id]
    },
    {
      "variable" = "aws:SourceArn",
      "values"   = [aws_guardduty_detector.main.arn]
    }
  ]

  features_additional = {
    "EKS_RUNTIME_MONITORING" = [
      "EKS_ADDON_MANAGEMENT"
    ],
    "RUNTIME_MONITORING" = [
      "EKS_ADDON_MANAGEMENT",
      "ECS_FARGATE_AGENT_MANAGEMENT",
      "EC2_AGENT_MANAGEMENT"
    ]
  }
}

# Variables

variable "region" {
  type        = string
  description = "AWS Region for the module."
  default     = "us-west-2"
}

variable "enabled_features" {
  type        = list(string)
  description = "List of GuardDuty Features to set to ENABLED for the aws_guardduty_detector.main resource."
  default     = []

  validation {
    condition = anytrue([
      length(var.enabled_features) == 0,
      alltrue([for feature in var.enabled_features : contains([
        "S3_DATA_EVENTS",
        "EKS_AUDIT_LOGS",
        "EBS_MALWARE_PROTECTION",
        "RDS_LOGIN_EVENTS",
        "EKS_RUNTIME_MONITORING",
        "LAMBDA_NETWORK_LOGS",
        "RUNTIME_MONITORING",
        "EKS_ADDON_MANAGEMENT",
        "ECS_FARGATE_AGENT_MANAGEMENT",
        "EC2_AGENT_MANAGEMENT"
      ], feature)])
    ])
    error_message = <<EOM
Invalid Feature name(s) detected in list. Must be empty (no features enabled), or contain one or more of the following:

"S3_DATA_EVENTS", "EKS_AUDIT_LOGS", "EBS_MALWARE_PROTECTION", "RDS_LOGIN_EVENTS",
"EKS_RUNTIME_MONITORING", "LAMBDA_NETWORK_LOGS", "RUNTIME_MONITORING", "EKS_ADDON_MANAGEMENT",
"ECS_FARGATE_AGENT_MANAGEMENT", and/or "EC2_AGENT_MANAGEMENT".
EOM
  }

  validation {
    condition = length([
      for feature in var.enabled_features : true if contains(
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
    "NONE"
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
