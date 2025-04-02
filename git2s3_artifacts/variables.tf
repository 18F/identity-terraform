# -- Variables --
variable "bucket_name_prefix" {
  description = <<EOM
REQUIRED. First substring in names for log_bucket,
inventory_bucket, and the public-artifacts bucket.
EOM
  type        = string
}

variable "log_bucket_name" {
  description = <<EOM
(OPTIONAL) Specific name of the bucket used for S3 logging.
Will default to $bucket_name_prefix.s3-access-logs.$account_id-$region
if not explicitly declared.
EOM
  type        = string
  default     = ""
}

variable "create_artifact_bucket" {
  description = <<EOM
(OPTIONAL) Whether or not to create the public-artifacts bucket,
and related resources, within this module. Set to 'false' if managing
said bucket in a separate/parent module.
EOM
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "inventory_bucket_name" {
  description = <<EOM
(OPTIONAL) Specific name of the S3 bucket used for collecting the S3 Inventory reports.
Will default to $bucket_name_prefix.s3-inventory.$account_id-$region
if not explicitly declared.
EOM
  type        = string
  default     = ""
}

variable "sse_algorithm" {
  description = "SSE algorithm to use to encrypt reports in S3 Inventory bucket."
  type        = string
  default     = "aws:kms"
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

  log_bucket = var.log_bucket_name != "" ? var.log_bucket_name : join(".",
    [
      var.bucket_name_prefix,
      "s3-access-logs",
      "${data.aws_caller_identity.current.account_id}-${var.region}"
    ]
  )

  inventory_bucket = var.inventory_bucket_name != "" ? var.inventory_bucket_name : join(".",
    [
      var.bucket_name_prefix,
      "s3-inventory",
      "${data.aws_caller_identity.current.account_id}-${var.region}"
    ]
  )
}
