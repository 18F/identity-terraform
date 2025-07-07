# Extract network performance info using an aws_ec2_instance_type data source.
# Each of these MUST point to a node type that has a NetworkPerformance value
# of 'Up to 5 Gigabit' or higher, or the threshold calculations for the
# redis_critical resources cannot be set properly.

data "aws_ec2_instance_type" "cache" {
  instance_type = var.node_type
}

resource "aws_cloudwatch_metric_alarm" "redis_high" {
  for_each            = var.alarms_map
  alarm_name          = "${var.cluster_id}-Redis-${each.value.alarm_name}-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = "AWS/ElastiCache"
  period              = var.period_duration
  threshold           = each.value.threshold_high
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${var.cluster_id} has exceeded ${each.value.threshold_high} ${each.value.alarm_descriptor} for over ${each.value.evaluation_periods * var.period_duration} seconds.
Please address this to avoid session lock-up or failure.
Runbook: ${var.runbook_url}
EOM
  alarm_actions       = var.high_alarm_action_arns

  dimensions = {
    CacheClusterId = var.cluster_id
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_critical" {
  for_each            = var.alarms_map
  alarm_name          = "${var.cluster_id}-Redis-${each.value.alarm_name}-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = "AWS/ElastiCache"
  period              = var.period_duration
  threshold           = each.value.threshold_critical
  statistic           = "Average"
  alarm_description   = <<EOM
Redis ${var.cluster_id} has exceeded ${each.value.threshold_critical} ${each.value.alarm_descriptor} for over ${each.value.evaluation_periods * var.period_duration} seconds.
This is a critical alert! Please address this to avoid session lock-up or failure.
Runbook: ${var.runbook_url}
EOM
  alarm_actions       = var.critical_alarm_action_arns

  dimensions = {
    CacheClusterId = var.cluster_id
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_network" {
  alarm_name          = "${var.cluster_id}-Redis-NetworkUsage-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1

  # NetworkBytesIn / NetworkBytesOut are in GB/min, while the network_performance
  # attribute of aws_ec2_instance_type is in Gbps. Conversion is done thusly:
  #
  #  threshold GB/minute = Gbps * 1/8 * 60 * 0.01 * threshold_percentage
  #  (or, simplified:)
  #  threshold GB/minute = Gbps * 0.075 * threshold_percentage
  #
  # where:
  #   1/8  =  bytes  -> bits
  #    60  =   sec   -> min
  #   0.01 = percent -> factor
  threshold = tonumber(
    regex(
      "[0-9]+",
      data.aws_ec2_instance_type.cache.network_performance
  )) * 0.075 * var.threshold_network

  alarm_description = <<EOM
Redis ${var.cluster_id} has exceeded ${var.threshold_network}% network utilization for over 60 seconds.
Please address this to avoid session lock-up or failure.
Runbook: ${var.runbook_url}
EOM
  alarm_actions     = var.critical_alarm_action_arns

  metric_query {
    id          = "e1"
    expression  = "SUM(METRICS())/1073741824" # Conversion of bytes to GB/minute
    label       = "Total Network Throughput"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "NetworkBytesIn"
      namespace   = "AWS/ElastiCache"
      period      = "60"
      stat        = "Average"

      dimensions = {
        CacheClusterId = var.cluster_id
      }
    }
  }
  metric_query {
    id = "m2"

    metric {
      metric_name = "NetworkBytesOut"
      namespace   = "AWS/ElastiCache"
      period      = "60"
      stat        = "Average"

      dimensions = {
        CacheClusterId = var.cluster_id
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
