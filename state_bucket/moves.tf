
####################################
# remove this file in a future PR! #
####################################
moved {
  from = aws_s3_bucket.s3-access-logs
  to   = aws_s3_bucket.s3_access_logs
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.s3-access-logs
  to   = aws_s3_bucket_server_side_encryption_configuration.s3_access_logs
}

moved {
  from = aws_s3_bucket_versioning.s3-access-logs
  to   = aws_s3_bucket_versioning.s3_access_logs
}

moved {
  from = aws_s3_bucket_ownership_controls.s3-access-logs
  to   = aws_s3_bucket_ownership_controls.s3_access_logs
}

moved {
  from = aws_s3_bucket_acl.s3-access-logs
  to   = aws_s3_bucket_acl.s3_access_logs
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.s3-access-logs
  to   = aws_s3_bucket_lifecycle_configuration.s3_access_logs
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.tf-state
  to   = aws_s3_bucket_server_side_encryption_configuration.tf_state
}

moved {
  from = aws_s3_bucket_versioning.tf-state
  to   = aws_s3_bucket_versioning.tf_state
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.tf-state
  to   = aws_s3_bucket_lifecycle_configuration.tf_state
}

moved {
  from = aws_s3_bucket_ownership_controls.tf-state
  to   = aws_s3_bucket_ownership_controls.tf_state
}

moved {
  from = aws_s3_bucket_acl.tf-state
  to   = aws_s3_bucket_acl.tf_state
}

moved {
  from = aws_s3_bucket_logging.tf-state
  to   = aws_s3_bucket_logging.tf_state
}

moved {
  from = aws_dynamodb_table.tf-lock-table
  to   = aws_dynamodb_table.tf_lock_table
}

moved {
  from = aws_appautoscaling_target.tf_lock_table_read_target
  to   = aws_appautoscaling_target.tf_lock_table_read
}

moved {
  from = aws_appautoscaling_policy.tf_lock_table_read_policy
  to   = aws_appautoscaling_policy.tf_lock_table_read
}

moved {
  from = aws_appautoscaling_target.tf_lock_table_write_target
  to   = aws_appautoscaling_target.tf_lock_table_write
}

moved {
  from = aws_appautoscaling_policy.tf_lock_table_write_policy
  to   = aws_appautoscaling_policy.tf_lock_table_write
}
