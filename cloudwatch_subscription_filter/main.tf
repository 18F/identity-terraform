resource "aws_cloudwatch_log_subscription_filter" "kinesis" {
    name = "${var.env_name}-${var.filter_name}"
    log_group_name = "${var.cloudwatch_log_group_name}"
    filter_pattern = "${var.cloudwatch_filter_pattern}"
    destination_arn = "${var.kinesis_arn}"
}