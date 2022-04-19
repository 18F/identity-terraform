output "zip_path" {
  description = "Output path/filename of ZIP file created from source code filename"
  value       = data.archive_file.lambda.output_path
}

output "lambda_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.lambda.arn
}

output "lambda_id" {
  description = "ID of the Lambda function"
  value       = aws_lambda_function.lambda.id
}

output "role_id" {
  description = "ID of the Lambda function's IAM role (if present)"
  value       = var.external_role_arn == "" ? aws_iam_role.lambda_access_role[0].id : ""
}
