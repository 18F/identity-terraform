locals {
  output_bucket_name = var.output_bucket_name == "" ? join(
    "-", [
      var.bucket_name_prefix,
      var.git2s3_project_name,
      "output",
      data.aws_caller_identity.current.account_id,
      data.aws_region.current.region
    ]
  ) : var.output_bucket_name
}

data "aws_iam_policy_document" "codebuild_output_bucket" {
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
      "arn:aws:s3:::${local.output_bucket_name}",
      "arn:aws:s3:::${local.output_bucket_name}/*"
    ]
  }
}

resource "aws_s3_bucket" "codebuild_output" {
  bucket        = local.output_bucket_name
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_ownership_controls" "codebuild_output" {
  bucket = aws_s3_bucket.codebuild_output.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "codebuild_output" {
  bucket = aws_s3_bucket.codebuild_output.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.codebuild_output]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codebuild_output" {
  bucket = aws_s3_bucket.codebuild_output.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm_output
    }

    blocked_encryption_types = var.s3_blocked_encryption_types
    bucket_key_enabled       = var.s3_bucket_key_enabled
  }
}

resource "aws_s3_bucket_versioning" "codebuild_output" {
  bucket = aws_s3_bucket.codebuild_output.id

  versioning_configuration {
    status = "Enabled"
  }
}

module "s3_config_codebuild_output" {
  source = "github.com/18F/identity-terraform//s3_config?ref=7a090cdc3647c08eb511b49e328caf33deef4f24"
  #source = "../s3_config"

  bucket_name          = aws_s3_bucket.codebuild_output.id
  region               = data.aws_region.current.region
  inventory_bucket_arn = var.inventory_bucket_arn
  logging_bucket_id    = var.logging_bucket_id
  block_public_access  = false
}

resource "aws_s3_bucket_policy" "codebuild_output" {
  bucket = aws_s3_bucket.codebuild_output.id
  policy = data.aws_iam_policy_document.codebuild_output_bucket.json
}
