output "member_clusters" {
  description = "IDs of cache clusters in Redis replication group"
  value       = aws_elasticache_replication_group.redis.member_clusters
}

output "port" {
  description = "Port number of the Redis replication group"
  value       = aws_elasticache_replication_group.redis.port
}

output "group_id" {
  description = "IDs of cache clusters in Redis replication group"
  value       = aws_elasticache_replication_group.redis.id
}

output "log_group" {
  description = "Name of the CloudWatch Log Group used by the replication group"
  value = var.external_cloudwatch_log_group == "" ? (
  aws_cloudwatch_log_group.redis[0].name) : var.external_cloudwatch_log_group
}

output "endpoint_address" {
  description = "Primary endpoint address of the replication group"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}
