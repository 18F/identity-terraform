variable "region" {
  description = "Region to create the secrets bucket in"
  default     = "us-west-2"
  type        = string
}

variable "bucket_name_prefix" {
  description = "Base name for the secrets bucket to create"
  type        = string
}

variable "log_prefix" {
  description = "Prefix inside the bucket where access logs will go"
  default     = "logs"
  type        = string
}

# This is optional to support the use case where multiple loadbalancers use the
# same S3 bucket with different log prefixes.
variable "use_prefix_for_permissions" {
  description = "Scope load balancer permissions by log_prefix"
  default     = false
  type        = bool
}

variable "force_destroy" {
  default     = false
  description = "Allow destroy even if bucket contains objects"
  type        = bool
}

variable "lifecycle_days_standard_ia" {
  description = "Number of days after object creation to move logs to Standard Infrequent Access. Set to 0 to disable."
  default     = 60
  type        = number
}

variable "lifecycle_days_glacier" {
  description = "Number of days after object creation to move logs to Glacier. Set to 0 to disable."
  default     = 365
  type        = number
}

variable "lifecycle_days_expire" {
  description = "Number of days after object creation to delete logs. Set to 0 to disable."
  default     = 0
  type        = number
}

variable "inventory_bucket_arn" {
  description = "ARN of the S3 bucket used for collecting the S3 Inventory reports."
  type        = string
}

variable "logging_bucket_id" {
  description = "Id of the S3 bucket used for collecting the S3 access events"
  type        = string
}

# To give ELBs the ability to upload logs to an S3 bucket, we need to create a
# policy that gives permission to a magical AWS account ID to upload logs to our
# bucket, which differs by region.  This table contaings those mappings, and was
# taken from:
# http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html
# Also see:
# https://github.com/hashicorp/terraform/pull/3756/files
# For the PR when ELB access logs were added in terraform to see an example of
# the supported test cases for this ELB to S3 logging configuration.
variable "elb_account_ids" {
  type        = map(string)
  description = "Mapping of region to ELB account ID"
  default = {
    us-east-1      = "127311923021"
    us-east-2      = "033677994240"
    us-west-1      = "027434742980"
    us-west-2      = "797873946194"
    ca-central-1   = "985666609251"
    eu-west-1      = "156460612806"
    eu-central-1   = "054676820928"
    eu-west-2      = "652711504416"
    ap-northeast-1 = "582318560864"
    ap-northeast-2 = "600734575887"
    ap-southeast-1 = "114774131450"
    ap-southeast-2 = "783225319266"
    ap-south-1     = "718504428378"
    sa-east-1      = "507241528517"
    us-gov-west-1  = "048591011584"
    cn-north-1     = "638102146993"
  }
}
