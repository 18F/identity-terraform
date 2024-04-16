output "kms-dead-letter-queue" {
  description = "Arn for the kms dead letter queue"
  value       = aws_sqs_queue.dead_letter.arn
}

output "kms-ct-events-queue" {
  description = "Arn for the kms cloudtrail queue"
  value       = aws_sqs_queue.kms_ct_events.arn
}

output "kms-logging-events-topic" {
  description = "SNS topic for kms logging events"
  value       = aws_sns_topic.kms_logging_events.arn
}

output "kms-cloudwatch-events-queue" {
  description = "Queue for kms logging events to cloudwatch"
  value       = aws_sqs_queue.kms_cloudwatch_events.arn
}

output "kms-log-groups" {
  description = "Names of the CloudWatch Log Groups in this module."
  value = [
    aws_cloudwatch_log_group.cloudtrail_processor.name,
    aws_cloudwatch_log_group.cloudtrail_requeue.name,
    aws_cloudwatch_log_group.cloudwatch_processor.name,
    aws_cloudwatch_log_group.event_processor.name,
    aws_cloudwatch_log_group.slack_processor.name,
    aws_cloudwatch_log_group.unmatched.name
  ]
}