output "s3_access_log_bucket" {
  value = aws_s3_bucket.s3-access-logs.id
}

output "inventory_bucket_arn" {
  value = aws_s3_bucket.inventory.arn
}
