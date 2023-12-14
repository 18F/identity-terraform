output "firehose_destination_arn" {
  description = "ARN of the CloudWatch Logs Destination for Kinesis Firehose."
  value       = aws_cloudwatch_log_destination.firehose.arn
}
