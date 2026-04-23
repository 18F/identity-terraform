# -- Data Sources --

data "github_ip_ranges" "ips" {
}

data "aws_iam_policy_document" "git2s3_output_bucket" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
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
  count = var.create_artifact_bucket ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", var.external_account_ids)
    }
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      aws_s3_bucket.artifact_bucket[count.index].arn,
      "${aws_s3_bucket.artifact_bucket[count.index].arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", var.external_account_ids)
    }
    actions = [
      "s3:Put*",
      "s3:Delete*",
    ]
    resources = [
      "${aws_s3_bucket.artifact_bucket[count.index].arn}/packer_config/*"
    ]
  }
}

# -- Resources --

resource "aws_cloudformation_stack" "git2s3" {
  name          = var.git2s3_stack_name
  template_body = file("${path.module}/git2s3.template")
  parameters = {
    AllowedIps = regex(
      "^[0-9.,\\/]+\\/32",
      substr(join(",", local.github_ipv4), 0, 512)
    )
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
  count         = var.create_artifact_bucket ? 1 : 0
  bucket        = "${var.bucket_name_prefix}-public-artifacts-${var.region}"
  force_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "artifact_bucket" {
  count  = var.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifact_bucket[count.index].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "artifact_bucket" {
  count  = var.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifact_bucket[count.index].id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.artifact_bucket]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifact_bucket" {
  count  = var.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifact_bucket[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
    }

    blocked_encryption_types = var.s3_blocked_encryption_types
    bucket_key_enabled       = var.s3_bucket_key_enabled
  }
}

resource "aws_s3_bucket_versioning" "artifact_bucket" {
  count  = var.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifact_bucket[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

module "s3_config" {
  count  = var.create_artifact_bucket ? 1 : 0
  source = "github.com/18F/identity-terraform//s3_config?ref=7a090cdc3647c08eb511b49e328caf33deef4f24"
  #source = "../s3_config"

  bucket_name          = aws_s3_bucket.artifact_bucket[count.index].id
  region               = var.region
  inventory_bucket_arn = var.inventory_bucket_arn
  logging_bucket_id    = var.logging_bucket_id
}

moved {
  from = aws_s3_bucket_logging.artifact_bucket[0]
  to   = module.s3_config[0].aws_s3_bucket_logging.access_logging[0]
}

resource "aws_s3_bucket_policy" "git2s3_output_bucket" {
  bucket = local.git2s3_output_bucket
  policy = data.aws_iam_policy_document.git2s3_output_bucket.json
}

resource "aws_s3_bucket_policy" "artifact_bucket" {
  count  = var.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifact_bucket[count.index].id
  policy = data.aws_iam_policy_document.artifact_bucket[count.index].json
}

resource "aws_s3_object" "git2s3_output_bucket_name" {
  count        = var.create_artifact_bucket ? 1 : 0
  bucket       = aws_s3_bucket.artifact_bucket[count.index].id
  key          = "git2s3/OutputBucketName"
  content      = local.git2s3_output_bucket
  content_type = "text/plain"
}
