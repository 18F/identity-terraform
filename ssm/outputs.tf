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

output "ssm_kms_arn" {
  description = "ARN of the SSM KMS key."
  value       = aws_kms_key.kms_ssm.arn
}
