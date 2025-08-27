output "trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.main.arn
}

output "trail_name" {
  description = "Name of the CloudTrail trail"
  value       = aws_cloudtrail.main.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the cloudtrail_default CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.cloudtrail_default.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the cloudtrail_default CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.cloudtrail_default.name
}

output "cloudwatch_logs_role_arn" {
  description = "ARN of the cloudtrail_cloudwatch_logs IAM role"
  value       = aws_iam_role.cloudtrail_cloudwatch_logs.arn
}

output "enable_log_file_validation" {
  description = "Whether or not enable_log_file_validation is enabled"
  value       = aws_cloudtrail.main.enable_log_file_validation
}

output "include_global_service_events" {
  description = "Whether or not include_global_service_events is enabled"
  value       = aws_cloudtrail.main.include_global_service_events
}

output "is_multi_region_trail" {
  description = "Whether or not is_multi_region_trail is enabled"
  value       = aws_cloudtrail.main.is_multi_region_trail
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket used by CloudTrail"
  value       = aws_s3_bucket.cloudtrail.id
}
