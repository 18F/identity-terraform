# main ALB dashboard

variable "dashboard_name" {
  description = "Human-visible name of the dashboard"
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
}

variable "target_group_label" {
  description = "Human label to explain what the target group servers are"
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group, used for displaying response time"
}

variable "asg_name" {
  description = "Name of the ASG behind the ALB. Used for displaying CPU usage"
}

variable "vertical_annotations" {
  description = "Raw JSON array of vertical annotations to add to all widgets"
  default     = "[]"
}

variable "region" {
  description = "AWS region"
  default     = "us-west-2"
}

variable "response_time_warning_threshold" {
  description = "Horizontal annotation for warning on response time graph"
  default     = 1
}

variable "error_rate_warning_threshold" {
  description = "Horizontal annotation for warning on error time graph"
  default     = 1
}

variable "error_rate_error_threshold" {
  description = "Horizontal annotation for error on error time graph"
  default     = 5
}

output "dashboard_arn" {
  # TODO: use a conditional to replace this after main TF12 rollout
  value = element(
    concat(aws_cloudwatch_dashboard.alb.*.dashboard_arn, [""]),
    0,
  )
}

resource "aws_cloudwatch_dashboard" "alb" {
  dashboard_name = var.dashboard_name
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 9,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "${var.alb_arn_suffix}", { "stat": "Sum", "period": 60, "color": "#2ca02c" } ],
                    [ ".", "HTTPCode_Target_3XX_Count", ".", ".", { "stat": "Sum", "period": 60 } ],
                    [ ".", "HTTPCode_Target_4XX_Count", ".", ".", { "stat": "Sum", "period": 60, "color": "#1f77b4" } ],
                    [ ".", "HTTPCode_Target_5XX_Count", ".", ".", { "stat": "Sum", "period": 60 } ]
                ],
                "region": "${var.region}",
                "title": "Backend target HTTP response codes from ${var.target_group_label}",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "annotations": {
                    "vertical": ${var.vertical_annotations}
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 27,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${var.alb_arn_suffix}", { "stat": "Sum", "period": 60 } ]
                ],
                "region": "${var.region}",
                "title": "Backend request volume",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "annotations": {
                    "vertical": ${var.vertical_annotations}
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 15,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_ELB_3XX_Count", "LoadBalancer", "${var.alb_arn_suffix}", { "period": 60, "stat": "Sum", "color": "#ff7f0e" } ],
                    [ ".", "HTTPCode_ELB_4XX_Count", ".", ".", { "period": 60, "stat": "Sum", "color": "#1f77b4" } ],
                    [ ".", "HTTPCode_ELB_5XX_Count", ".", ".", { "period": 60, "stat": "Sum", "color": "#d62728" } ]

                ],
                "region": "${var.region}",
                "title": "Frontend errors from ALB",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "annotations": {
                    "vertical": ${var.vertical_annotations}
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 21,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${var.target_group_arn_suffix}", "LoadBalancer", "${var.alb_arn_suffix}", { "stat": "p50", "color": "#1f77b4", "label": "p50" } ],
                    [ "...", { "stat": "p90", "label": "p90" } ],
                    [ "...", { "stat": "p99", "label": "p99" } ]
                ],
                "region": "${var.region}",
                "title": "Backend response time",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "annotations": {
                    "horizontal": [
                        {
                            "color": "#d68181",
                            "value": ${var.response_time_warning_threshold}
                        }
                    ],
                    "vertical": ${var.vertical_annotations}
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 39,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", "${var.asg_name}", { "period": 60, "color": "#c7c7c7", "stat": "Average", "yAxis": "left" } ],
                    [ ".", "GroupTerminatingInstances", ".", ".", { "period": 60, "color": "#d62728" } ],
                    [ ".", "GroupPendingInstances", ".", ".", { "period": 60, "color": "#ff7f0e" } ],
                    [ ".", "GroupInServiceInstances", ".", ".", { "period": 60, "color": "#2ca02c" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "title": "Instance counts: ASG ${var.asg_name}",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 33,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.asg_name}", { "period": 60 } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "title": "Average CPU Utilization: ASG ${var.asg_name}",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 45,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", "${var.target_group_arn_suffix}", "LoadBalancer", "${var.alb_arn_suffix}", { "period": 60, "color": "#d62728" } ],
                    [ ".", "HealthyHostCount", ".", ".", ".", ".", { "period": 60, "color": "#2ca02c" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "title": "ELB health check results (stacked)"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 9,
            "width": 24,
            "height": 6,
            "properties": {
                "metrics": [
                    [ { "expression": "(target_errs + elb_5xx) / (elb_3xx + elb_4xx + elb_5xx + target_total) * 100", "label": "Overall Error Rate", "id": "err_rate", "color": "#9467bd", "visible": false } ],
                    [ { "expression": "(target_errs / target_total) * 100", "label": "Backend Error Rate", "id": "target_err_rate", "color": "#d62728", "period": 60, "stat": "Sum" } ],
                    [ { "expression": "elb_5xx / (elb_3xx + elb_4xx + elb_5xx + target_total) * 100", "label": "ELB Frontend Error Rate", "id": "elb_err_rate", "color": "#000" } ],
                    [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${var.alb_arn_suffix}", { "id": "target_total", "label": "Backend RequestCount", "color": "#1f77b4", "period": 60, "stat": "Sum", "yAxis": "right", "visible": false } ],
                    [ ".", "HTTPCode_Target_5XX_Count", ".", ".", { "period": 60, "stat": "Sum", "id": "target_errs", "yAxis": "right", "visible": false, "color": "#ffbb78" } ],
                    [ ".", "HTTPCode_ELB_3XX_Count", ".", ".", { "period": 60, "stat": "Sum", "id": "elb_3xx", "yAxis": "right", "visible": false, "color": "#c49c94" } ],
                    [ ".", "HTTPCode_ELB_4XX_Count", ".", ".", { "period": 60, "stat": "Sum", "id": "elb_4xx", "yAxis": "right", "visible": false, "color": "#bcbd22" } ],
                    [ ".", "HTTPCode_ELB_5XX_Count", ".", ".", { "period": 60, "stat": "Sum", "id": "elb_5xx", "yAxis": "right", "visible": false, "color": "#c5b0d5" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "label": "Percent",
                        "showUnits": false,
                        "min": 0
                    }
                },
                "title": "Error rate",
                "period": 300,
                "annotations": {
                    "horizontal": [
                        {
                            "color": "#ffbb80",
                            "value": ${var.error_rate_warning_threshold}
                        },
                        {
                            "color": "#d68181",
                            "value": ${var.error_rate_error_threshold}
                        }
                    ]
                },
                "legend": {
                    "position": "bottom"
                }
            }
        }
    ]
}
EOF

}

