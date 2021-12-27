output "ssm_access_role_policy" {
  description = "Body of the ssm_access_role_policy, in JSON"
  value       = data.aws_iam_policy_document.ssm_access_role_policy.json
}

output "ssm_cw_logs" {
  description = "Name of the CloudWatch Log Group for SSM access logging."
  value       = aws_cloudwatch_log_group.cw_ssm_logs.name
}
