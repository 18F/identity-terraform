output "bucket_id" {
  description = "ID (name) of the S3 bucket."
  value       = aws_s3_bucket.bucket.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.bucket.arn
}

output "kms" {
  description = "ARN of the KMS key used with the S3 bucket; generated if var.sse_config.create_kms_key = true."
  value = var.sse_config.create_kms_key ? {
    arn    = aws_kms_key.bucket[0].arn
    key_id = aws_kms_key.bucket[0].key_id
  } : null
}
