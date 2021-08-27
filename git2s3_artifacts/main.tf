# -- Providers --
terraform {
  required_providers {
    github = {
      source  = "hashicorp/github"
      version = "~> 2.9"
    }
  }
  required_version = ">= 0.13"
}

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
  type    = string
  default = ""
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
  type    = string
  default = ""
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
  git2s3_output_bucket = chomp(aws_cloudformation_stack.git2s3.outputs["OutputBucketName"])

  github_ipv4 = compact([
    for ip in data.github_ip_ranges.ips.git : try(regex(local.ip_regex, ip),"")
  ])

  inventory_bucket = var.inventory_bucket_name != "" ? var.inventory_bucket_name : join(".",
    [
      var.bucket_name_prefix,
      "s3-inventory",
      "${data.aws_caller_identity.current.account_id}-${var.region}"
    ]
  )

  ip_regex = "^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\/(?:[0-2][0-9]|[3][0-2])"

  log_bucket = var.log_bucket_name != "" ? var.log_bucket_name : join(".",
    [
      var.bucket_name_prefix,
      "s3-access-logs",
      "${data.aws_caller_identity.current.account_id}-${var.region}"
    ]
  )
}

# -- Data Sources --
data "aws_caller_identity" "current" {
}

data "github_ip_ranges" "ips" {
}

data "aws_iam_policy_document" "git2s3_output_bucket" {
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", var.external_account_ids)
    }
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::${local.git2s3_output_bucket}",
      "arn:aws:s3:::${local.git2s3_output_bucket}/*"
    ]
  }
}

data "aws_iam_policy_document" "artifact_bucket" {
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", var.external_account_ids)
    }
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      aws_s3_bucket.artifact_bucket.arn,
      "${aws_s3_bucket.artifact_bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", var.external_account_ids)
    }
    actions = [
      "s3:Put*",
      "s3:Delete*",
    ]
    resources = [
      "${aws_s3_bucket.artifact_bucket.arn}/packer_config/*"
    ]
  }
}

# -- Resources --

resource "aws_cloudformation_stack" "git2s3" {
  name          = var.git2s3_stack_name
  template_body = file("${path.module}/git2s3.template")
  parameters    = {
    AllowedIps          = substr(join(",",local.github_ipv4), 0, 512)
    QSS3BucketName      = "aws-quickstart"
    OutputBucketName    = ""
    ScmHostnameOverride = ""
    ExcludeGit          = "True"
    VPCId               = ""
    CustomDomainName    = ""
    QSS3BucketRegion    = "us-east-1"
    ApiSecret           = ""
    QSS3KeyPrefix       = "quickstart-git2s3/"
    VPCCidrRange        = ""
    SubnetIds           = ""
  }
  capabilities = ["CAPABILITY_IAM"]
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "${var.bucket_name_prefix}-public-artifacts-${var.region}"
  acl    = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  logging {
    target_bucket = local.log_bucket
    target_prefix = "${var.bucket_name_prefix}-public-artifacts-${var.region}"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.sse_algorithm
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

module "s3_config" {
  source = "github.com/18F/identity-terraform//s3_config?ref=cad9776e886147179d563a9b058b92b3dfbf3957"

  bucket_name_override = aws_s3_bucket.artifact_bucket.id
  region               = var.region
  inventory_bucket_arn = "arn:aws:s3:::${local.inventory_bucket}"
}

resource "aws_s3_bucket_policy" "git2s3_output_bucket" {
  bucket = local.git2s3_output_bucket
  policy = data.aws_iam_policy_document.git2s3_output_bucket.json
}

resource "aws_s3_bucket_policy" "artifact_bucket" {
  bucket = aws_s3_bucket.artifact_bucket.id
  policy = data.aws_iam_policy_document.artifact_bucket.json
}

resource "aws_s3_bucket_object" "git2s3_output_bucket_name" {
  bucket       = aws_s3_bucket.artifact_bucket.id
  key          = "git2s3/OutputBucketName"
  content      = local.git2s3_output_bucket
  content_type = "text/plain"
}

# -- Outputs --

output "output_bucket" {
  value = aws_s3_bucket_object.git2s3_output_bucket_name.key
}
