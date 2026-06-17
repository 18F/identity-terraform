resource "aws_kms_key" "bucket" {
  count = var.sse_config.create_kms_key ? 1 : 0

  region                  = var.region
  description             = "KMSKeyForS3Bucket-${aws_s3_bucket.bucket.id}"
  deletion_window_in_days = 7
  enable_key_rotation     = var.sse_config.kms_key_rotation
  policy                  = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "bucket" {
  count = var.sse_config.create_kms_key ? 1 : 0

  name = var.sse_config.custom_kms_alias == "" ? "alias/s3/${replace(
    aws_s3_bucket.bucket.id, ".", "_"
  )}" : var.sse_config.custom_kms_alias
  region        = var.region
  target_key_id = aws_kms_key.bucket[count.index].key_id
}
