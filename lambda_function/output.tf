output "function_name" {
  value = aws_lambda_function.lambda.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.lambda.arn
}

output "lambda_role_name" {
  value = aws_iam_role.lambda.name
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.lambda.name
}