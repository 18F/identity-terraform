output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.lambda.function_name
}

output "lambda_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.lambda.arn
}

output "lambda_role_name" {
  description = "Name of the IAM role used by the Lambda function."
  value       = aws_iam_role.lambda.name
}

output "lambda_role_arn" {
  description = "ARN of the IAM role used by the Lambda function."
  value       = aws_iam_role.lambda.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch Log Group used to log executions by the Lambda function."
  value       = aws_cloudwatch_log_group.lambda.name
}

output "layer_arn" {
  description = "ARN of the Lambda Layer, if using."
  value       = local.layer_enabled ? aws_lambda_layer_version.layer[0].arn : ""
}
