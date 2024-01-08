output "kinesis_destination_arn" {
  description = "ARN of the CloudWatch Logs Destination for the Kinesis Data Stream."
  value       = aws_cloudwatch_log_destination.kinesis.arn
}
