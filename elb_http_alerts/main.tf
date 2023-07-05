# -- Variables --

variable "env_name" {
  description = "Environment name, for prefixing the generated metric names"
  type        = string
}

variable "lb_name" {
  description = "Name of the Load Balancer"
  type        = string
}

variable "lb_type" {
  description = "Type of Load Balancer (ELB or ALB)"
  type        = string
}

variable "alarm_actions" {
  description = "A list of ARNs to notify when the LB alarms fire"
  type        = list(string)
}

variable "lb_arn_suffix" {
  description = "Load Balancer ARN Suffix"
  type        = string
  default     = ""
}

variable "lb_threshold" {
  description = "Number of errors to trigger LB 5xx alarm"
  type        = number
  default     = 30
}

variable "target_threshold" {
  description = "Number of errors to trigger targets/instances 5xx alarm"
  type        = number
  default     = 150
}

locals {
  lb_type_data = {
    ALB = {
      "namespace"     = "AWS/ApplicationELB",
      "lb_metric"     = "HTTPCode_ELB_5XX_Count",
      "target_metric" = "HTTPCode_Target_5XX_Count"
    },
    ELB = {
      "namespace"     = "AWS/ELB",
      "lb_metric"     = "HTTPCode_ELB_5XX",
      "target_metric" = "HTTPCode_Backend_5XX"
    }
  }
}

# -- Resources --

resource "aws_cloudwatch_metric_alarm" "elb_http_5xx" {
  alarm_name        = "${var.lb_name}_${var.lb_type}_HTTP-5XX"
  alarm_description = <<EOM
HTTP 5XX errors served by the ${var.lb_name} ${var.lb_type} without hosts
EOM
  namespace         = lookup(local.lb_type_data, var.lb_type)["namespace"]
  metric_name       = lookup(local.lb_type_data, var.lb_type)["lb_metric"]

  dimensions = var.lb_type == "ALB" ? {
    LoadBalancer = var.lb_arn_suffix
    } : {
    LoadBalancerName = var.lb_name
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.lb_threshold
  period              = 60
  datapoints_to_alarm = 1
  evaluation_periods  = 1

  treat_missing_data = "missing"

  alarm_actions = var.alarm_actions

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "target_http_5xx" {
  alarm_name        = "${var.lb_name}_Target_HTTP-5XX"
  alarm_description = <<EOM
HTTP 5XX errors served by hosts in ${var.lb_name} ${var.lb_type}
EOM
  namespace         = lookup(local.lb_type_data, var.lb_type)["namespace"]
  metric_name       = lookup(local.lb_type_data, var.lb_type)["target_metric"]
  dimensions = var.lb_type == "ALB" ? {
    LoadBalancer = var.lb_arn_suffix
    } : {
    LoadBalancerName = var.lb_name
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.target_threshold
  period              = 300
  evaluation_periods  = 1

  treat_missing_data = "notBreaching"

  alarm_actions = var.alarm_actions

  lifecycle {
    create_before_destroy = true
  }
}

