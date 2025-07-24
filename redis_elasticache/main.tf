locals {
  cluster_id          = var.cluster_id_override == "" ? "${var.env_name}-${var.app_name}" : var.cluster_id_override
  data_tier_node_type = "r6gd"
}

resource "aws_cloudwatch_log_group" "redis" {
  count = var.external_cloudwatch_log_group == "" ? 1 : 0

  name              = "elasticache-${local.cluster_id}-redis"
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = var.prevent_tf_log_deletion

  tags = {
    environment = var.env_name
  }
}

resource "aws_elasticache_parameter_group" "redis" {
  name   = "${local.cluster_id}-params-${var.family_name}"
  family = var.family_name

  dynamic "parameter" {
    for_each = var.group_parameters
    content {
      name  = parameter.value["name"]
      value = parameter.value["value"]
    }
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = local.cluster_id
  description                = "Multi-AZ Redis cluster for ${var.cluster_purpose} in ${var.env_name} environment"
  engine                     = "redis"
  engine_version             = var.engine_version
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_clusters
  parameter_group_name       = aws_elasticache_parameter_group.redis.name
  security_group_ids         = var.security_group_ids
  subnet_group_name          = var.subnet_group_name
  port                       = var.port
  apply_immediately          = true
  multi_az_enabled           = true
  automatic_failover_enabled = true # note: t2.* instances don't support automatic failover
  at_rest_encryption_enabled = var.encrypt_at_rest
  transit_encryption_enabled = var.encrypt_in_transit
  notification_topic_arn     = var.general_notification_arn

  # enable data tiering if using a data tier enabled node
  data_tiering_enabled = strcontains(var.node_type, local.data_tier_node_type)

  log_delivery_configuration {
    destination = var.external_cloudwatch_log_group == "" ? (
    aws_cloudwatch_log_group.redis[0].name) : var.external_cloudwatch_log_group
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }
}

module "alarms" {
  # Terraform can't determine member_clusters in an aws_elasticache_replication_group before a plan/apply operation,
  # so this for/format block must be used instead. This is apparently an AWS API restriction -- not a
  # Terraform/provider one -- so there are no current plans to attempt a more seamless/dynamic integration.
  # Details: https://github.com/hashicorp/terraform-provider-aws/issues/36342
  for_each = toset([
    for i in range(1, (var.num_cache_clusters + 1)) : format("%s-%03d", local.cluster_id, i)
  ])

  source = "github.com/18F/identity-terraform//redis_alarms?ref=28994c76cf074bbc45b88e9f038ce96a4e492198"
  #source = "../redis_alarms"

  cluster_id                 = each.key
  alarms_map                 = var.alarms_map
  high_alarm_action_arns     = var.high_alarm_action_arns
  critical_alarm_action_arns = var.critical_alarm_action_arns
  period_duration            = var.period_duration
  runbook_url                = var.runbook_url
  node_type                  = trimprefix(var.node_type, "cache.")
  threshold_network          = var.threshold_network

  depends_on = [
    aws_elasticache_replication_group.redis
  ]
}
