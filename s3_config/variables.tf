variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket to add logging/inventory/public access block configs to."
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
  description = "S3 bucket used for logging S3 access events. CANNOT be the same bucket targeted by this module!"
  default     = ""

  validation {
    condition = anytrue([
      var.logging_bucket_id == "",
      var.logging_bucket_id != var.bucket_name
    ])
    error_message = "Logging bucket and target bucket cannot be the same!"
  }
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
