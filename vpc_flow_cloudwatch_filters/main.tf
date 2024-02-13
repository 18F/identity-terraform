variable "env_name" {
  description = "Environment name, for prefixing the generated metric names"
}

variable "log_group_name_override" {
  default     = ""
  description = "The name of the log group, overriding the default <env_name>_flow_log_group"
}

variable "metric_namespace" {
  description = "Namespace to use for created cloudwatch metrics"
  default     = "LogMetrics/vpc_flow"
}

variable "treat_missing_data" {
  description = "How to treat missing metric data in the rejections alarm. https://www.terraform.io/docs/providers/aws/r/cloudwatch_metric_alarm.html#treat_missing_data"
  default     = "missing"
}

variable "alarm_actions" {
  type        = list(string)
  description = "A list of ARNs to notify when the VPC rejection alarm fires"
}

variable "default_field_list" {
  type        = list(any)
  description = "Default fields for flow logs"
  default = [
    "version",
    "accountId",
    "interfaceId",
    "srcAddr",
    "dstAddr",
    "srcPort",
    "dstPort",
    "protocol",
    "packets",
    "bytes",
    "start",
    "end",
    "action",
    "logStatus",
    "vpcId",
    "subnetId",
    "instanceId",
    "tcpFlags",
    "type",
    "pktSrcAddr",
    "pktDstAddr",
    "region",
    "azId",
    "subLocationType",
    "subLocationId",
    "pktSrcAwsService",
    "pktDstAwsService",
    "flowDirection",
    "trafficPath"
  ]
}

variable "vpc_flow_rejections_total_fields" {
  type = any
  default = {
    action = "action=REJECT"
  }
}

variable "vpc_flow_rejections_internal_fields" {
  type = any
  default = {
    action  = "action=REJECT"
    srcAddr = "srcAddr=172.16.*"
  }
}

variable "vpc_flow_rejections_unexpected_fields" {
  type = any
  default = {
    action  = "action=REJECT"
    srcAddr = "srcAddr=172.16.*"
    dstAddr = "dstAddr!=192.88.99.255"
    srcPort = "srcPort!=26 && srcPort!=443 && srcPort!=3128 && srcPort!=5044"
  }
}


locals {
  log_group_name                        = var.log_group_name_override == "" ? "${var.env_name}_flow_log_group" : var.log_group_name_override
  vpc_flow_rejections_total_fields      = join(", ", [for i, v in var.default_field_list : coalesce(try(var.vpc_flow_rejections_total_fields[v], null), v)])
  vpc_flow_rejections_internal_fields   = join(", ", [for i, v in var.default_field_list : coalesce(try(var.vpc_flow_rejections_internal_fields[v], null), v)])
  vpc_flow_rejections_unexpected_fields = join(", ", [for i, v in var.default_field_list : coalesce(try(var.vpc_flow_rejections_unexpected_fields[v], null), v)])
}

resource "aws_cloudwatch_log_metric_filter" "vpc_flow_rejections_total" {
  name           = "${var.env_name}-vpc-flow-rejections-total"
  pattern        = "[${local.vpc_flow_rejections_total_fields}]"
  log_group_name = local.log_group_name
  metric_transformation {
    namespace     = var.metric_namespace
    name          = "${var.env_name}/TotalRejections"
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "vpc_flow_rejections_internal" {
  name = "${var.env_name}-vpc-flow-rejections-internal"

  # Same pattern as above plus srcAddr=172.16.*
  pattern        = "[${local.vpc_flow_rejections_internal_fields}]"
  log_group_name = local.log_group_name
  metric_transformation {
    namespace     = var.metric_namespace
    name          = "${var.env_name}/InternalRejections"
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "vpc_flow_rejections_unexpected" {
  name = "${var.env_name}-vpc-flow-rejections-unexpected"

  # Same as above plus filtering out:
  # src port 443, 3128, and 5044 (which seem to be timed out connections)
  # src port 26, which seems to be SSH health checks
  # destination host 192.88.99.255 for https://console.aws.amazon.com/support/v1?region=us-west-2#/case/?displayId=5319857611&language=en
  pattern        = "[${local.vpc_flow_rejections_unexpected_fields}]"
  log_group_name = local.log_group_name
  metric_transformation {
    namespace     = var.metric_namespace
    name          = "${var.env_name}/UnexpectedRejections"
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "vpc_rejection_alarm" {
  alarm_name        = "${var.env_name}-vpc-flow-rejections-unexpected"
  alarm_description = "Alarm when the VPC flow log shows any unexpected traffic [TF]"
  namespace         = var.metric_namespace
  metric_name       = "${var.env_name}/UnexpectedRejections"

  # alert when sum(denials) >= 1 for any 1 minute out of 15 eval periods
  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  period              = 60
  datapoints_to_alarm = 1
  evaluation_periods  = 15

  treat_missing_data = var.treat_missing_data

  alarm_actions = var.alarm_actions
}

