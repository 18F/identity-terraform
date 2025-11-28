resource "aws_appautoscaling_target" "tf_lock_table_read" {
  count = var.remote_state_enabled

  max_capacity       = var.tf_lock_table_read_capacity["maximum"]
  min_capacity       = var.tf_lock_table_read_capacity["minimum"]
  resource_id        = "table/${aws_dynamodb_table.tf_lock_table[count.index].name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "tf_lock_table_read" {
  count = var.remote_state_enabled

  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.tf_lock_table_read[count.index].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.tf_lock_table_read[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.tf_lock_table_read[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.tf_lock_table_read[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = 70
  }
}

resource "aws_appautoscaling_target" "tf_lock_table_write" {
  count = var.remote_state_enabled

  max_capacity       = var.tf_lock_table_write_capacity["maximum"]
  min_capacity       = var.tf_lock_table_write_capacity["minimum"]
  resource_id        = "table/${aws_dynamodb_table.tf_lock_table[count.index].name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "tf_lock_table_write" {
  count = var.remote_state_enabled

  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.tf_lock_table_write[count.index].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.tf_lock_table_write[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.tf_lock_table_write[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.tf_lock_table_write[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = 70
  }
}
