# -- Variables --
variable "bucket_name_prefix" {
  description = "First substring in S3 bucket name of $bucket_name_prefix-public-artifacts-$region"
  type        = string
}

variable "log_bucket" {
  description = "Name of the bucket used for S3 logging."
  type        = string
  default     = "s3-access-logs"
}

variable "region" {
  default     = "us-west-2"
  description = "AWS Region"
}

variable "inventory_bucket_arn" {
  description = "ARN of the S3 bucket used for collecting the S3 Inventory reports."
  type        = string
}

variable "sse_algorithm" {
  description = "SSE algorithm to use to encrypt reports in S3 Inventory bucket."
  type        = string
  default     = "aws:kms"
}

variable "git2s3_stack_name" {
  description = "Name for the Git2S3 CloudFormation Stack"
  type        = string
}

variable "external_account_ids" {
  description = "List of additional AWS account IDs, if any, to be permitted access to the public-artifacts bucket"
  type        = list(string)
  default     = []
}

locals {
  git2s3_output_bucket = chomp(aws_cloudformation_stack.git2s3.outputs["OutputBucketName"])
  log_bucket           = "${var.bucket_name_prefix}.s3-access-logs.${data.aws_caller_identity.current.account_id}-${var.region}"
  inventory_bucket     = "${var.bucket_name_prefix}.s3-inventory.${data.aws_caller_identity.current.account_id}-${var.region}"
}

# -- Data Sources --
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
      "arn:aws:s3:::${var.artifact_bucket}",
      "arn:aws:s3:::${var.artifact_bucket}/*"
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
      "arn:aws:s3:::${var.artifact_bucket}/packer_config/*"
    ]
  }
}

# -- Resources --

resource "aws_cloudformation_stack" "git2s3" {
  name          = "CodeSync-IdentityBaseImage"
  template_body = file("${path.module}/git2s3.template")
  parameters    = {
    AllowedIps          = data.github_ip_ranges.ips.git
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
    target_bucket = aws_s3_bucket.s3-access-logs.id
    target_prefix = "${local.state_bucket}/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}


resource "aws_s3_bucket_policy" "git2s3_output_bucket" {
  bucket = local.git2s3_output_bucket
  policy = data.aws_iam_policy_document.git2s3_output_bucket.json
}

resource "aws_s3_bucket_policy" "artifact_bucket" {
  bucket = var.artifact_bucket
  policy = data.aws_iam_policy_document.artifact_bucket.json
}

resource "aws_s3_bucket_object" "git2s3_output_bucket_name" {
  bucket       = var.artifact_bucket
  key          = "git2s3/OutputBucketName"
  content      = local.git2s3_output_bucket
  content_type = "text/plain"
}

output "output_bucket" {
  value = aws_s3_bucket_object.git2s3_output_bucket_name.key
}
