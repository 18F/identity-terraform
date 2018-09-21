output "cloudwatch_subscription_filter_name" {
    description = "CloudWatch subscription filter name"
    value = "${aws_cloudwatch_log_subscription_filter.name}"
}