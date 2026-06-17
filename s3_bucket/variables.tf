variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket to create"
}

variable "force_destroy" {
  type        = bool
  description = "Allow destruction of the S3 bucket, even if it contains objects."
  default     = true
}

variable "bucket_tags" {
  type        = map(string)
  description = "Tags for the S3 bucket."
  default = {
    #environment = var.env_name
  }
}

variable "region" {
  type        = string
  description = "AWS Region for the module."
  default     = "us-west-2"
}

variable "inventory_config" {
  type = map(object({
    included_versions = string
    frequency         = string
    filter_prefix     = optional(string)
    format            = string
    bucket_account_id = optional(number)
    bucket_sse        = string
    bucket_kms_key_id = optional(string)
    inventory_prefix  = optional(string)
    optional_fields   = optional(list(string))
  }))
  description = <<EOM
Map/object var containing configurations related to S3 Inventory. Leave/set to {} to disable inventory configuration.
EOM
  default = {
    "FullBucketDailyInventory" = {
      included_versions = "All"
      frequency         = "Daily"
      format            = "Parquet"
      bucket_sse        = "sse_s3"
      optional_fields = [
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
  }

  validation {
    condition     = length(var.inventory_config) < 2
    error_message = "Can only define one configuration block in var.inventory_config"
  }
}

variable "inventory_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket for collecting S3 Inventory reports. CANNOT be the bucket created by this module!"
  default     = ""

  validation {
    condition = anytrue([
      var.inventory_bucket_arn == "",
      var.inventory_bucket_arn != var.bucket_name
    ])
    error_message = "Inventory bucket and target bucket cannot be the same!"
  }
}

variable "logging_bucket_id" {
  type        = string
  description = "ID (name) of the S3 bucket for logging S3 access events. CANNOT be the bucket created by this module!"
  default     = ""

  validation {
    condition = anytrue([
      var.logging_bucket_id == "",
      var.logging_bucket_id != var.bucket_name
    ])
    error_message = "Logging bucket and target bucket cannot be the same!"
  }
}

variable "block_public_access" {
  description = "Whether or not to enable the public access block for this bucket."
  type        = bool
  default     = true
}

variable "sse_config" {
  type = object({
    algorithm                = string
    create_kms_key           = optional(bool, false)
    kms_key_rotation         = optional(bool)
    custom_kms_key           = optional(string)
    custom_kms_alias         = optional(string)
    bucket_key_enabled       = bool
    blocked_encryption_types = optional(list(string), ["SSE-C"])
  })
  description = "Object var containing all configuration related to S3 server-side encryption."
  default = {
    algorithm          = "AES256"
    bucket_key_enabled = false
  }
}

variable "bucket_acl" {
  type        = string
  description = <<EOM
Type of bucket ACL to use, if any (generally discouraged for newer buckets); leave blank to skip creation.
Valid values: private, public-read, public-read-write, aws-exec-read, authenticated-read,
bucket-owner-read, bucket-owner-full-control, log-delivery-write.
EOM
  default     = ""
  #default = "private" # legacy/common default
}

variable "object_ownership" {
  type        = string
  description = "Object Ownership. Valid values: BucketOwnerPreferred, ObjectWriter or BucketOwnerEnforced"
  default     = "BucketOwnerPreferred"
}

variable "lifecycle_minimum_object_size" {
  type        = string
  description = <<EOM
The default minimum object size behavior applied to the lifecycle configuration, if var.lifecycle_rules is defined.
Valid values: varies_by_storage_class, all_storage_classes_128K
EOM
  default     = "varies_by_storage_class"
}

variable "versioning_status" {
  type        = string
  description = "Status of Bucket Versioning. Valid values are 'Enabled' or 'Suspended'; 'Disabled' cannot be used."
  default     = "Enabled"
}

variable "lifecycle_rules" {
  type = map(object({
    status                      = string
    filter_prefix               = optional(string, "/")
    abort_days_after_initiation = optional(number)
    transition = optional(object({
      date          = optional(string)
      days          = optional(number)
      storage_class = string
    }))
    expiration = optional(object({
      date                         = optional(string)
      days                         = optional(number)
      expired_object_delete_marker = optional(bool)
    }))
    noncurrent_version_expiration = optional(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = number
    }))
    noncurrent_version_transition = optional(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = number
      storage_class             = string
    }))
  }))
  description = <<EOM
Detailed map of lifecycle configuration rules. Each must have a 'status', and one or more types of transition/expiration
blocks. Leave empty (i.e. '{}') to skip creating the aws_s3_bucket_lifecycle_configuration resource entirely.
EOM
  default     = {}
}

variable "bucket_policy_doc" {
  type        = string
  description = <<EOM
An additonal source_policy_document (in JSON) to add to the S3 bucket policy, if using one.
Will default to only using the contents of the s3_secure_connections policy document if not set.
EOM
  default     = ""

  validation {
    condition     = length(var.bucket_policy_doc) != 0 ? can(jsondecode(var.bucket_policy_doc)) : true
    error_message = "var.bucket_policy_doc is not valid JSON"
  }
}

variable "key_policy_doc" {
  type        = string
  description = <<EOM
An additonal source_policy_document (in JSON) to add to the KMS key policy, if using one.
Will default to only using the basic IAMAndRoot statement if not set.
EOM
  default     = ""

  validation {
    condition     = length(var.key_policy_doc) != 0 ? can(jsondecode(var.key_policy_doc)) : true
    error_message = "var.bucket_policy_doc is not valid JSON"
  }
}
