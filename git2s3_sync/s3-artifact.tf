locals {
  artifact_bucket_name = var.artifact_bucket_name == "" ? join(
    "-", [
      var.bucket_name_prefix,
      "public-artifacts",
      data.aws_caller_identity.current.account_id,
      data.aws_region.current.name
    ]
  ) : var.artifact_bucket_name
}

data "aws_iam_policy_document" "artifact_bucket" {
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
      aws_s3_bucket.artifact_bucket.arn,
      "${aws_s3_bucket.artifact_bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket        = local.artifact_bucket_name
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_ownership_controls" "artifact_bucket" {
  bucket = aws_s3_bucket.artifact_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "artifact_bucket" {
  bucket = aws_s3_bucket.artifact_bucket.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.artifact_bucket]
}


resource "aws_s3_bucket_server_side_encryption_configuration" "artifact_bucket" {
  bucket = aws_s3_bucket.artifact_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm_artifact
    }
  }
}

resource "aws_s3_bucket_versioning" "artifact_bucket" {
  bucket = aws_s3_bucket.artifact_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

module "s3_config_artifact" {
  source = "github.com/18F/identity-terraform//s3_config?ref=cea57dfeaa2e437852ffa488606bf37f954dce12"
  #source = "../s3_config"

  bucket_name_override = aws_s3_bucket.artifact_bucket.id
  region               = data.aws_region.current.name
  inventory_bucket_arn = "arn:aws:s3:::${local.inventory_bucket}"
  logging_bucket_id    = local.log_bucket
}

resource "aws_s3_bucket_policy" "artifact_bucket" {
  bucket = aws_s3_bucket.artifact_bucket.id
  policy = data.aws_iam_policy_document.artifact_bucket.json
}
