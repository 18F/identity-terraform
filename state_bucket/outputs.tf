output "s3_access_log_bucket" {
  value       = aws_s3_bucket.s3_access_logs.id
  description = "ID/Name of the S3 Access Logging Bucket"
}

output "inventory_bucket_arn" {
  value       = aws_s3_bucket.inventory.arn
  description = "ARN of the S3 Inventory Bucket"
}
