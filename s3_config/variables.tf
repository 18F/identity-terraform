# -- Locals --
locals {
  bucket_fullname = var.bucket_name_override != "" ? var.bucket_name_override : join(".",
    [
      var.bucket_name_prefix,
      var.bucket_name,
      "${data.aws_caller_identity.current.account_id}-${var.region}"
    ]
  )
}

# -- Variables --
variable "bucket_name_prefix" {
  description = "First substring in S3 bucket name of $bucket_name_prefix.$bucket_name.$account_id-$region"
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "Main/second substring in S3 bucket name of $bucket_name_prefix.$bucket_name.$account_id-$region"
  type        = string
  default     = ""
}

variable "bucket_name_override" {
  description = "Set this to override the normal bucket naming schema."
  type        = string
  default     = ""
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

variable "inventory_bucket_sse" {
  type        = string
  description = "SSE algorithm used by the S3 Inventory bucket specified by var.inventory_bucket_arn"
  default     = "sse_s3"

  validation {
    condition     = contains(["sse_s3", "sse_kms"], var.inventory_bucket_sse)
    error_message = "var.inventory_bucket_sse must be 'sse_s3' or 'sse_kms'"
  }
}

variable "inventory_bucket_kms_key_id" {
  type        = string
  description = "KMS key used by the S3 Inventory bucket if var.inventory_bucket_sse = 'sse_kms'"
  default     = ""

  validation {
    condition = var.inventory_bucket_sse == "sse_kms" ? can(regex(
      "^arn:aws:kms:::[a-zA-Z0-9.-]+$", var.inventory_bucket_kms_key_id
    )) : true
    error_message = "var.inventory_bucket_kms_key_id must be a valid KMS ARN if var.inventory_bucket_sse is 'sse_kms'"
  }
}

variable "logging_bucket_id" {
  type        = string
  description = "Name of the S3 bucket used for logging S3 access events."
}

variable "optional_fields" {
  description = "List of optional data fields to collect in S3 Inventory reports."
  type        = list(string)
  default = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus",
    "ObjectLockRetainUntilDate",
    "ObjectLockMode",
    "ObjectLockLegalHoldStatus",
    "IntelligentTieringAccessTier",
  ]
}

variable "block_public_access" {
  description = "Whether or not to enable the public access block for this bucket."
  type        = bool
  default     = true
}
