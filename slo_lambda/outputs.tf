output "cw_log_group" {
  description = "Name of the CloudWatch Log Group for the windowed_slo Lambda."
  value       = aws_cloudwatch_log_group.windowed_slo_lambda.name
}
