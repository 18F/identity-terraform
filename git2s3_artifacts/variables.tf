# -- Variables --
variable "bucket_name_prefix" {
  type        = string
  description = "First substring in name for the public-artifacts bucket."
}

variable "create_artifact_bucket" {
  description = <<EOM
(OPTIONAL) Whether or not to create the public-artifacts bucket, and related resources, within this module.
Set to 'false' if managing said bucket in a separate/parent module.
EOM
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "inventory_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket used for collecting S3 Inventory reports."
}

variable "logging_bucket_id" {
  type        = string
  description = "ID (name) of the S3 bucket used for logging S3 access events."
}

variable "sse_algorithm" {
  type        = string
  description = "SSE algorithm to use to encrypt objects in the public-artifacts S3 bucket, if creating one."
  default     = "aws:kms"
}

variable "s3_bucket_key_enabled" {
  type        = bool
  description = "Whether or not to use a Bucket Key for the S3 bucket in this module."
  default     = false
}

variable "s3_blocked_encryption_types" {
  type        = list(string)
  description = "Single-item list of SSE types to block for object uploads to the S3 bucket in this module."
  default = [
    "NONE"
  ]

  validation {
    condition     = contains(["NONE", "SSE-C"], var.s3_blocked_encryption_types[0])
    error_message = "var.s3_blocked_encryption_types must be set to 'NONE' or 'SSE-C'."
  }
}

variable "git2s3_stack_name" {
  description = "REQUIRED. Name for the Git2S3 CloudFormation Stack"
  type        = string
}

variable "external_account_ids" {
  description = <<EOM
(OPTIONAL) List of additional AWS account IDs, if any, to be permitted
access to the public-artifacts bucket.
EOM
  type        = list(string)
  default     = []
}

locals {
  ip_regex = "^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\/(?:[0-2][0-9]|[3][0-2])"
  github_ipv4 = compact([
    for ip in data.github_ip_ranges.ips.git : try(regex(local.ip_regex, ip), "")
  ])

  git2s3_output_bucket = chomp(aws_cloudformation_stack.git2s3.outputs["OutputBucketName"])
}
