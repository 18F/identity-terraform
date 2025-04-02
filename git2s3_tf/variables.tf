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

variable "log_bucket_name" {
  description = <<EOM
(OPTIONAL) Specific name of the bucket used for S3 logging.
Will default to $bucket_name_prefix.s3-access-logs.$account_id-$region
if not explicitly declared.
EOM
  type        = string
  default     = ""
}

variable "inventory_bucket_name" {
  description = <<EOM
(OPTIONAL) Specific name of the S3 bucket used for collecting the
S3 Inventory reports for all buckets in the module. Will default to
$bucket_name_prefix.s3-inventory.$account_id-$region
if not explicitly declared.
EOM
  type        = string
  default     = ""
}

variable "sse_algorithm_artifact" {
  description = <<EOM
SSE algorithm to use to encrypt objects in the artifact_bucket, if using.
EOM
  type        = string
  default     = "aws:kms"
}

variable "sse_algorithm_output" {
  description = <<EOM
SSE algorithm to use to encrypt objects in the output_bucket.
EOM
  type        = string
  default     = "AES256"
}

variable "cloudwatch_retention_days" {
  description = <<EOM
Number of days to retain CloudWatch Log Groups/Streams for all Log Groups
defined in/created by this module.
EOM
  type        = number
  default     = 365
}

variable "prevent_tf_log_deletion" {
  description = <<EOM
Whether or not to stop Terraform from ACTUALLY destroying the
CloudWatch Log Group for the Git2S3 CodeBuild Project (vs. simply
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
REQUIRED. Main identifier used as the name for the CodeBuild project,
for the git-pull Lambda function, and for numerous other resources
within this module.
EOM
  type        = string
  default     = "git2s3"
}

variable "secrets_bucket" {
  description = <<EOM
REQUIRED. Full name of an externally-built S3 bucket which will store
the SSH key (used for repo access by the git-pull Lambda function)
after it has been created by the lambda_sshkey function.
EOM
  type        = string
}

variable "use_allowed_ips" {
  description = <<EOM
Whether or not to use a list of allowed IP ranges, either via
var.allowed_ip_ranges or data.github_ip_ranges.ips.git,
to provide access for the API Gateway + git-pull Lambda function
to connect to the source repo.
MUST be 'true' if var.api_secret is left blank.
EOM
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = <<EOM
(OPTIONAL) List of IP CIDR blocks allowed for communication between
the API Gateway + git-pull Lambda function and the repo they connect
to. If not specified, will instead use the GitHub CIDR ranges pulled
in by data.github_ip_ranges.ips.git as long as var.use_allowed_ips
is 'true'; otherwise, will default to IP ranges from BitBucket Cloud
IP as specified in the original CloudFormation template.
EOM
  type        = list(string)
  default     = []
}

variable "api_secret" {
  description = <<EOM
(OPTIONAL) API secret used to authenticate access to webhooks in GitHub,
GitLab, and other Git services. If a webhook payload header contains a
matching secret, IP address authentication (via those included in
var.allowed_ip_ranges) is bypassed. API secrets cannot contain
commas (,), backward slashes (\\), or quotes (\").
CANNOT BE LEFT BLANK if var.use_allowed_ips is 'false'.
EOM
  type        = string
  default     = ""
}

variable "exclude_git" {
  description = <<EOM
Whether or not to omit the .git directory from the ZIP file
created by the git-pull Lambda function.
EOM
  type        = bool
  default     = true
}
