locals {
  log_bucket       = "${var.bucket_name_prefix}.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  state_bucket     = "${var.bucket_name_prefix}.tf-state.${data.aws_caller_identity.current.account_id}-${var.region}"
  inventory_bucket = "${var.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
}

variable "bucket_name_prefix" {
  description = "First substring in S3 bucket name of $bucket_name_prefix.$bucket_name.$account_id-$region"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "remote_state_enabled" {
  description = <<EOM
Whether to manage the remote state bucket
and DynamoDB lock table (1 for true, 0 for false).
EOM
  default     = 1
  type        = number
}

variable "state_lock_table" {
  description = "Name of the DynamoDB table to use for state locking with the S3 state backend, e.g. 'terraform_locks'"
  default     = "terraform_locks"
  type        = string
}

variable "sse_algorithm" {
  description = "SSE algorithm to use to encrypt reports in S3 Inventory bucket."
  type        = string
  default     = "aws:kms"
}

variable "terraform_lock_deletion_protection" {
  description = "Wheter to enable deletion protection for DynamoDB table."
  type        = bool
  default     = true
}
