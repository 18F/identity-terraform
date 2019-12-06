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

output "kms-elasticsearch-events-queue" {
  description = "Queue for kms logging events to elasticsearch"
  value       = aws_sqs_queue.kms_elasticsearch_events.arn
}

output "kms-cloudwatch-events-queue" {
  description = "Queue for kms logging events to cloudwatch"
  value       = aws_sqs_queue.kms_cloudwatch_events.arn
}

