variable "env_name" {
    description = "Environment name, for prefixing the generated metric names"
}

variable "log_group_name_override" {
    default = ""
    description = "The name of the log group, overriding the default <env_name>_flow_log_group"
}

variable "metric_namespace" {
    description = "Namespace to use for created cloudwatch metrics"
    default = "LogMetrics/vpc_flow"
}

variable "treat_missing_data" {
    description = "How to treat missing metric data in the rejections alarm. https://www.terraform.io/docs/providers/aws/r/cloudwatch_metric_alarm.html#treat_missing_data"
    default = "missing"
}

variable "alarm_actions" {
    type = "list"
    description = "A list of ARNs to notify when the squid denied alarm fires"
}

locals {
    log_group_name = "${var.log_group_name_override == "" ? "${var.env_name}_flow_log_group" : var.log_group_name_override}"
}


resource "aws_cloudwatch_log_metric_filter" "vpc_flow_rejections_total" {
    name = "${var.env_name}-vpc-flow-rejections-total"
    pattern = "[version, accountID,interfaceID, srcAddr, dstAddr, srcPort, dstPort, protocol, packets, bytes, startTime, endTime, action=REJECT, logStatus]"
    log_group_name = "${local.log_group_name}"
    metric_transformation {
        namespace = "${var.metric_namespace}"
        name = "${var.env_name}/TotalRejections"
        value = 1
        default_value = 0
    }
}

resource "aws_cloudwatch_log_metric_filter" "vpc_flow_rejections_internal" {
    name = "${var.env_name}-vpc-flow-rejections-internal"
    pattern = "[version, accountID,interfaceID, srcAddr=172.16.*, dstAddr, srcPort, dstPort, protocol, packets, bytes, startTime, endTime, action=REJECT, logStatus]"
    log_group_name = "${local.log_group_name}"
    metric_transformation {
        namespace = "${var.metric_namespace}"
        name = "${var.env_name}/InternalRejections"
        value = 1
        default_value = 0
    }
}
