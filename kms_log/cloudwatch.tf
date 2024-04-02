resource "aws_cloudwatch_dashboard" "kms_log" {
  dashboard_name = "${var.env_name}-kms-logging"
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 6,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/SQS", "NumberOfMessagesReceived", "QueueName", "${aws_sqs_queue.dead_letter.name}", { "stat": "Sum", "period": 86400 } ]
                ],
                "view": "singleValue",
                "region": "us-west-2",
                "title": "Dead Letter Day",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/Lambda", "IteratorAge", "FunctionName", "${local.cw_processor_lambda_name}" ]
                ],
                "region": "us-west-2",
                "title": "Cloudwatch Kinesis queue age"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "${aws_sqs_queue.kms_ct_events.name}" ]
                ],
                "region": "us-west-2",
                "title": "CloudTrail SQS queue depth"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/SQS", "NumberOfMessagesReceived", "QueueName", "${aws_sqs_queue.kms_cloudwatch_events.name}" ],
                    [ ".", "ApproximateNumberOfMessagesVisible", ".", "." ],
                    [ ".", "NumberOfMessagesDeleted", ".", "." ]
                ],
                "region": "us-west-2",
                "title": "CloudWatch events queue"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/Kinesis", "PutRecord.Success", "StreamName", "${aws_kinesis_stream.datastream.name}" ],
                    [ ".", "GetRecords.Success", ".", "." ]
                ],
                "region": "us-west-2",
                "title": "Kinesis"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 3,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", "${aws_dynamodb_table.kms_events.name}", "Operation", "PutItem", { "period": 300 } ],
                    [ "...", "GetItem" ],
                    [ "...", "Query" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-west-2",
                "period": 300,
                "title": "DynamoDB Latency"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 9,
            "width": 12,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "${aws_dynamodb_table.kms_events.name}" ],
                    [ ".", "ConsumedWriteCapacityUnits", ".", "." ]
                ],
                "region": "us-west-2",
                "title": "DynamoDB Capacity"
            }
        }
    ]
}
EOF

}

resource "aws_cloudwatch_metric_alarm" "dead_letter" {
  for_each = toset([
    aws_sqs_queue.dead_letter.name,
    aws_sqs_queue.unmatched_slack_dead_letter.name,
    aws_sqs_queue.cloudtrail_requeue_dead_letter.name,
  ])

  alarm_name          = each.key
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfMessagesReceived"
  namespace           = "AWS/SQS"
  dimensions = {
    QueueName = each.key
  }
  period             = "180"
  statistic          = "Sum"
  threshold          = 1
  alarm_description  = "This alarm notifies when messages are on dead letter queue"
  treat_missing_data = "ignore"
  alarm_actions      = var.alarm_sns_topic_arns
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_lambda_backlog" {
  alarm_name          = "${var.env_name}-cloudwatch-kms-backlog"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  namespace           = "AWS/Lambda"
  metric_name         = "IteratorAge"
  dimensions = {
    FunctionName = local.cw_processor_lambda_name
  }
  period    = "180"
  statistic = "Maximum"

  # 3600000 ms = 1 hour
  threshold          = 3600000
  alarm_description  = "Kinesis backlog for ${var.env_name}-cloudwatch-kms"
  treat_missing_data = "ignore"
  alarm_actions      = var.alarm_sns_topic_arns
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_lambda_backlog" {
  alarm_name          = "${var.env_name}-cloudtrail-kms-backlog"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  dimensions = {
    QueueName = aws_sqs_queue.kms_ct_events.name
  }
  period    = "180"
  statistic = "Maximum"

  # the previous alarm is measured in milliseconds, this is a raw number of
  # messages - it has never gone above 1, but if the Lambda breaks it will
  # get to 10000 in under an hour
  threshold          = 10000
  alarm_description  = "Kinesis backlog for ${var.env_name}-cloudtrail-kms"
  treat_missing_data = "ignore"
  alarm_actions      = var.alarm_sns_topic_arns
}
