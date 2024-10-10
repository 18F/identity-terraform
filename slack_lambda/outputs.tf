output "cw_log_group" {
  description = "Name of the CloudWatch Log Group for the slack_lambda function."
  value       = module.slack_lambda.cloudwatch_log_group_name
}
