output "ssm_access_role_policy" {
  description = "Body of the ssm_access_role_policy, in JSON"
  value       = data.aws_iam_policy_document.ssm_access_role_policy.json
}

output "ssm_session_logs" {
  description = "Name of the CloudWatch Log Group for SSM access logging."
  value       = aws_cloudwatch_log_group.ssm_session_logs.name
}

output "ssm_cmd_logs" {
  description = "Name of the CloudWatch Log Group for SSM command logging."
  value       = aws_cloudwatch_log_group.ssm_cmd_logs.name
}

output "ssm_kms_key_id" {
  description = "ID of the KMS key used for encryption of S3/CloudWatch logs."
  value       = aws_kms_key.kms_ssm.id
}

output "ssm_kms_key_arn" {
  description = "ARN of the KMS key used for encryption of S3/CloudWatch logs."
  value       = aws_kms_key.kms_ssm.arn
}

output "ssm_kms_alias" {
  description = "Alias of the KMS key used for encryption of S3/CloudWatch logs."
  value       = aws_kms_alias.kms_ssm.name
}
