output "zip_path" {
  description = "Output path/filename of ZIP file created from source code filename"
  value       = data.archive_file.lambda.output_path
}

output "lambda_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.lambda.arn
}

