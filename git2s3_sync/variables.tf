variable "artifact_bucket_name" {
  description = <<EOM
(OPTIONAL) Name of the S3 bucket where public artifacts will be stored.
Will default to pattern of '$bucket_name_prefix-public-artifacts-$aws_region'
if no value is specified.
EOM
  type        = string
  default     = ""
}

variable "output_bucket_name" {
  description = <<EOM
(OPTIONAL) Name of the S3 bucket where the CodeBuild project will upload
ZIP files when it successfully finishes a build. Will default to pattern of
'$bucket_name_prefix-$git2s3_project_name-output-$aws_region'
if no value is specified.
EOM
  type        = string
  default     = ""
}

variable "bucket_name_prefix" {
  description = <<EOM
REQUIRED. First substring in names for log_bucket, and inventory_bucket,
as well as the artifact_bucket, and output_bucket, if those buckets'
corresponding '_name' variables are not specified.
EOM
  type        = string
}

variable "inventory_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket used for collecting S3 Inventory reports."
}

variable "logging_bucket_id" {
  type        = string
  description = "ID (name) of the S3 bucket used for logging S3 access events."
}

variable "sse_algorithm_artifact" {
  description = <<EOM
(OPTIONAL) SSE algorithm to use to encrypt objects in the
artifact_bucket resource, if using.
EOM
  type        = string
  default     = "aws:kms"
}

variable "sse_algorithm_output" {
  description = <<EOM
REQUIRED. SSE algorithm to use to encrypt objects in the output_bucket.
EOM
  type        = string
  default     = "AES256"
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

variable "cloudwatch_retention_days" {
  description = <<EOM
REQUIRED. Number of days to retain CloudWatch Log Groups/Streams
for all Log Groups defined in/created by this module.
EOM
  type        = number
  default     = 365
}

variable "prevent_tf_log_deletion" {
  description = <<EOM
REQUIRED. Whether or not to stop Terraform from ACTUALLY destroying
the CloudWatch Log Group for the Git2S3 CodeBuild Project (vs. simply
removing from state) upon marking the resource for deletion.
EOM
  type        = bool
  default     = true
}

variable "external_account_ids" {
  description = <<EOM
REQUIRED. List of AWS account IDs to be permitted access to
the artifacts bucket (if using) and the output_bucket.
EOM
  type        = list(string)
}

variable "git2s3_project_name" {
  description = <<EOM
(OPTIONAL) Main identifier used as the name for the CodeBuild project,
for the git-pull Lambda function, and for numerous other resources
within this module. MUST be lowercase, and only contain alphanumeric
characterts and hyphens, as it is used to name the S3 bucket
that ZIP files of the repository/branches are uploaded to.
EOM
  type        = string
  default     = "git2s3"
  validation {
    condition     = can(regex("^[0-9a-z-]+$", var.git2s3_project_name))
    error_message = "Can only be lowercase alphanumeric characters and hyphens."
  }
}

variable "allowed_ip_ranges" {
  description = <<EOM
(OPTIONAL) Comma-separated list, as a string, of IP CIDR blocks allowed
for communication between the API Gateway + git-pull Lambda function and
the repo they connect to. If not specified, will instead use the GitHub
CIDR ranges pulled in by the data.github_ip_ranges.ips.git data source.
EOM
  type        = string
  default     = ""
}

variable "ssh_key_secret_version" {
  description = <<EOM
REQUIRED. Version number (integer) of the Secrets Manager secret containing
the text of the SSH keypair (public and private keys) that is created
via ephemeraltls_private_key.git2s3. ONLY update if rotating/replacing
the key.
EOM
  type        = number
  default     = 1
}
