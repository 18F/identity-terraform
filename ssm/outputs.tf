output "ssm_access_role_policy" {
  description = "Body of the ssm_access_role_policy, in JSON"
  value       = data.aws_iam_policy_document.ssm_access_role_policy.json
}

output "ssm_kms_arn" {
  description = "ARN of the KMS key used for S3/session/log encryption."
  value       = aws_kms_key.ssm.arn
}
