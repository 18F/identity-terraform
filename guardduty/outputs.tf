output "detector_id" {
  description = "ID of the GuardDuty Detector."
  value       = aws_guardduty_detector.main.id
}

output "publishing_destination" {
  description = "ID of the GuardDuty Publishing Destination (S3)."
  value       = aws_guardduty_publishing_destination.s3.id
}

output "cw_log_group" {
  description = "Name of the GuardDuty Findings CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.guardduty_findings.name
}

output "kms_key_id" {
  description = "ID of the KMS key used to encrypt GuardDuty publishing."
  value       = aws_kms_key.guardduty.key_id
}

output "kms_key_alias" {
  description = "Alias of the KMS key used to encrypt GuardDuty publishing."
  value       = aws_kms_alias.guardduty.name
}