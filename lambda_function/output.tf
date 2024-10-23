output "function_name" {
  value = aws_lambda_function.lambda.function_name
}

output "lambda_arn" {
  value       = aws_lambda_function.lambda.arn
  description = "The ARN of the Lambda Function"
}

output "lambda_role_name" {
  value       = aws_iam_role.lambda.name
  description = "The name of the IAM Role associated with the lambda"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.lambda.name
  description = "The name of the cloudwatch log group associated with the lambda"
}

