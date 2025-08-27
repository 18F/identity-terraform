data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

resource "aws_cloudwatch_log_group" "cloudtrail_default" {
  name              = "CloudTrail/DefaultLogGroup"
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = var.prevent_tf_log_deletion
}

resource "aws_cloudtrail" "main" {
  name                          = var.trail_name
  enable_log_file_validation    = var.enable_log_file_validation
  enable_logging                = var.enable_logging
  include_global_service_events = var.include_global_service_events
  is_multi_region_trail         = var.is_multi_region_trail
  is_organization_trail         = var.is_organization_trail
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_default.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_logs.arn

  # only use if var.basic_event_selectors is anything but []
  dynamic "event_selector" {
    for_each = var.basic_event_selectors
    content {
      include_management_events        = event_selector.value.include_management_events
      read_write_type                  = event_selector.value.read_write_type
      exclude_management_event_sources = event_selector.value.excluded_sources

      dynamic "data_resource" {
        for_each = event_selector.value.data_resources
        content {
          type   = data_resource.key
          values = data_resource.value
        }
      }
    }
  }

  # only use if var.advanced_event_selectors is anything but []
  dynamic "advanced_event_selector" {
    for_each = var.advanced_event_selectors
    content {
      name = advanced_event_selector.value.name

      # required
      field_selector {
        field  = "eventCategory"
        equals = [advanced_event_selector.value.category]
      }

      # optional, will record read AND write if not specified
      dynamic "field_selector" {
        for_each = advanced_event_selector.value.read_only != null ? [advanced_event_selector.value.read_only] : []
        content {
          field  = "readOnly"
          equals = [field_selector.value]
        }
      }

      # only use with event_category = "NetworkActivity"
      dynamic "field_selector" {
        for_each = advanced_event_selector.value.error_code != null ? [advanced_event_selector.value.error_code] : []
        content {
          field  = "errorCode"
          equals = [field_selector.value]
        }
      }

      # required with event_category = "Data"
      dynamic "field_selector" {
        for_each = advanced_event_selector.value.category == "Data" ? [advanced_event_selector.value.resource_type] : []
        content {
          field  = "resources.type"
          equals = [field_selector.value]
        }
      }

      # all other possible fields, specify with operator(s)
      dynamic "field_selector" {
        for_each = advanced_event_selector.value.fields != null ? advanced_event_selector.value.fields : {}
        content {
          field = field_selector.key

          equals          = try(field_selector.value.equals, null)
          not_equals      = try(field_selector.value.not_equals, null)
          ends_with       = try(field_selector.value.ends_with, null)
          not_ends_with   = try(field_selector.value.not_ends_with, null)
          not_starts_with = try(field_selector.value.not_starts_with, null)
          starts_with     = try(field_selector.value.starts_with, null)
        }
      }

    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_cloudwatch_log_group.cloudtrail_default
  ]
}
