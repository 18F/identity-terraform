output "snow_incident_topic_arn" {
  description = "ARN for SNS topic"
  value       = aws_sns_topic.snow_incident.arn
}
