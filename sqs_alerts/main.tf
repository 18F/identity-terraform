locals {
  #Inflight message limits are determined by queue type. Options are standard or FIFO
  inflight_messages_limit = var.queue_type == "standard" ? 120000 : 20000
}

resource "aws_cloudwatch_metric_alarm" "inflight_messages" {
  count = var.enabled ? 1 : 0

  alarm_name        = "SQSInflightMessages_${var.queue_name}"
  alarm_description = "SQS Inflight Messages has exceeded ${var.inflight_threshold}%"

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold                 = local.inflight_messages_limit * (var.inflight_threshold * 0.01)
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = []

  metric_name = "ApproximateNumberOfMessagesNotVisible"
  namespace   = "AWS/SQS"
  period      = var.period
  statistic   = "Maximum"
  dimensions = {
    QueueName = var.queue_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "age_of_oldest_message" {
  count = var.enabled ? 1 : 0

  alarm_name        = "SQSAgeOfOldestMessage_${var.queue_name}"
  alarm_description = "SQS Age of Messages in the queue"

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold                 = var.age_of_oldest_message_threshold
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = []

  metric_name = "ApproximateAgeOfOldestMessage"
  namespace   = "AWS/SQS"
  period      = var.period
  statistic   = "Maximum"
  dimensions = {
    QueueName = var.queue_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "message_size" {
  count = var.enabled ? 1 : 0

  alarm_name        = "SQSMessageSize_${var.queue_name}"
  alarm_description = "SQS Messages sizes have exceeded ${var.message_size_threshold}%"

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.evaluation_periods
  threshold                 = var.max_message_size * (var.message_size_threshold * 0.01)
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = []

  metric_name = "SentMessageSize"
  namespace   = "AWS/SQS"
  period      = var.period
  statistic   = "Maximum"
  dimensions = {
    QueueName = var.queue_name
  }

  lifecycle {
    create_before_destroy = true
  }
}
