output "member_clusters" {
  description = "IDs of cache clusters in Redis replication group"
  value       = aws_elasticache_replication_group.redis.member_clusters
}

output "log_group" {
  description = "Name of the CloudWatch Log Group used by the replication group"
  value       = aws_cloudwatch_log_group.redis.name
}
