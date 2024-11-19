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
