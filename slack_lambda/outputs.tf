output "cw_log_group" {
  description = "Name of the CloudWatch Log Group for the slack_lambda function."
  value       = aws_cloudwatch_log_group.slack_lambda.name
}
