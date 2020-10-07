variable "access_keys_rotated_max_access_key_age" {
  description = "Maximum age of access keys in days"
  type        = string
  default     = "90"
}

variable "acm_certificate_expiration_check_days_to_expiration" {
  description = "Number of days before expiration of ACM certificate"
  type        = string
  default     = "90"
}

variable "cw_loggroup_retention_period_check_min_retention_time" {
  description = "Number of days to retain cw logs"
  type        = string
  default     = "90"
}

variable "ec2_volume_inuse_check_delete_on_termination" {
  description = "Checks for ec2 volume delete on termination"
  type        = string
  default     = "TRUE"
}

variable "guard_duty_non_archived_findings_days_low_sev" {
  description = "Number of days for non archived low sev findings in GuardDuty"
  type        = string
  default     = "180"
}

variable "guard_duty_non_archived_findings_days_medium_sev" {
  description = "Number of days for non archived medium sev findings in GuardDuty"
  type        = string
  default     = "90"
}

variable "guard_duty_non_archived_findings_days_high_sev" {
  description = "Number of days for non archived high sev findings in GuardDuty"
  type        = string
  default     = "30"
}

variable "iam_password_policy_max_password_age" {
  description = "IAM password policy max password age"
  type        = string
  default     = "90"
}

variable "iam_password_policy_minimum_password_length" {
  description = "IAM password policy minimum password length"
  type        = string
  default     = "14"
}

variable "iam_password_policy_password_reuse_prevention" {
  description = "IAM password policy password reuse prevention"
  type        = string
  default     = "24"
}

variable "iam_password_policy_require_lowercase_characters" {
  description = "IAM password policy require lowercase characters"
  type        = string
  default     = "TRUE"
}

variable "iam_password_policy_require_uppercase_characters" {
  description = "IAM password policy require uppercase characters"
  type        = string
  default     = "TRUE"
}

variable "iam_password_policy_require_numbers" {
  description = "IAM password policy require numbers"
  type        = string
  default     = "TRUE"
}

variable "iam_password_policy_require_symbols" {
  description = "IAM password policy require symbols"
  type        = string
  default     = "TRUE"
}

variable "iam_user_unused_credentials_check_max_credential_usage_age" {
  description = "IAM user credentials unused max age"
  type        = string
  default     = "90"
}

variable "restricted_incoming_traffic_blocked_port1" {
  description = "Restricted traffic incoming port 1"
  type        = string
  default     = "20"
}

variable "restricted_incoming_traffic_blocked_port2" {
  description = "Restricted traffic incoming port 2"
  type        = string
  default     = "21"
}

variable "restricted_incoming_traffic_blocked_port3" {
  description = "Restricted traffic incoming port 3"
  type        = string
  default     = "3389"
}

variable "restricted_incoming_traffic_blocked_port4" {
  description = "Restricted traffic incoming port 4"
  type        = string
  default     = "3306"
}

variable "restricted_incoming_traffic_blocked_port5" {
  description = "Restricted traffic incoming port 5"
  type        = string
  default     = "4333"
}

variable "s3_account_level_public_access_blocks_block_public_acls" {
  description = "S3 Public access block set to block public acls"
  type        = string
  default     = "TRUE"
}

variable "s3_account_level_public_access_blocks_block_public_policy" {
  description = "S3 Public access block set to block public policy"
  type        = string
  default     = "TRUE"
}

variable "s3_account_level_public_access_blocks_ignore_public_acls" {
  description = "S3 Public access block set to ignore public acls"
  type        = string
  default     = "TRUE"
}

variable "s3_account_level_public_access_blocks_restrict_public_buckets" {
  description = "S3 Public access block set to restrict_public_buckets"
  type        = string
  default     = "TRUE"
}

variable "vpc_sg_open_only_to_authorized_ports_authorized_tcp_ports" {
  description = "Vpc security group only to authorized tcp ports"
  type        = string
  default     = "443"
}

# Note - Must be defined as single string.  See https://docs.aws.amazon.com/config/latest/developerguide/vpc-sg-open-only-to-authorized-ports.html
variable "vpc_sg_open_only_to_authorized_ports_authorized_udp_ports" {
  description = "Vpc security group only to authorized udp ports"
  type        = string
  default     = "1020-1025"
}
