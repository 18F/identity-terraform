# main RDS dashboard

variable "enabled" {
  default = 1
}

variable "dashboard_name" {
  description = "Human-visible name of the dashboard"
}

variable "region" {
  description = "AWS Region"
}

variable "db_instance_identifier" {
  description = "DB Instance Identifier of the RDS Instance"
}

variable "iops" {
  description = "IOPS quota for the instance, if nonzero will be used to create a horizontal annotation on the R/W IOPS widget"
  default     = 0
}

variable "vertical_annotations" {
  description = "Raw JSON array of vertical annotations to add to all widgets"
  default     = "[]"
}

output "dashboard_arn" {
  value = element(
    concat(aws_cloudwatch_dashboard.main.*.dashboard_arn, [""]),
    0,
  )
}

locals {
  iops_annotation_value = <<EOM
{
    "color": "#d62728",
    "label": "IOPS Quota",
    "value": ${var.iops}
}
EOM

  iops_horizontal_annotations = var.iops > 0 ? "[${local.iops_annotation_value}]" : "[]"
}

resource "aws_cloudwatch_dashboard" "main" {
  count = var.enabled

  dashboard_name = var.dashboard_name
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.db_instance_identifier}", { "stat": "Maximum" } ]
                ],
                "region": "${var.region}",
                "title": "CPUUtilization",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
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
            "y": 6,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", "${var.db_instance_identifier}", { "stat": "Maximum" } ],
                    [ ".", "WriteIOPS", ".", ".", { "stat": "Maximum" } ]
                ],
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                },
                "title": "R/W IOPS",
                "period": 300,
                "annotations": {
                    "horizontal": ${local.iops_horizontal_annotations},
                    "vertical": ${var.vertical_annotations}
                }
            }
        },
        {
            "type": "metric",
            "x": 6,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${var.db_instance_identifier}", { "stat": "Maximum" } ]
                ],
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "title": "DB Connections",
                "annotations": {
                    "vertical": ${var.vertical_annotations}
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "${var.db_instance_identifier}", { "stat": "Minimum" } ]
                ],
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "title": "Freeable memory",
                "annotations": {
                    "vertical": ${var.vertical_annotations}
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 12,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "ReadLatency", "DBInstanceIdentifier", "${var.db_instance_identifier}", { "stat": "Maximum" } ],
                    [ ".", "WriteLatency", ".", ".", { "stat": "Maximum" } ]
                ],
                "region": "${var.region}",
                "title": "Latency",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                },
                "annotations": {
                    "horizontal": [
                        {
                            "color": "#d62728",
                            "label": "High latency",
                            "value": 0.1
                        }
                    ],
                    "vertical": ${var.vertical_annotations}
                }
            }
        },
        {
            "type": "metric",
            "x": 18,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${var.db_instance_identifier}", { "label": "FreeStorageSpace", "stat": "Minimum" } ]
                ],
                "region": "${var.region}",
                "title": "Disk Free",
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
            "y": 18,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "DiskQueueDepth", "DBInstanceIdentifier", "${var.db_instance_identifier}", { "stat": "Maximum" } ]
                ],
                "region": "${var.region}",
                "title": "DiskQueueDepth",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                },
                "annotations": {
                    "horizontal": [
                        {
                            "color": "#2ca02c",
                            "label": "Low utilization",
                            "value": 0.5
                        },
                        {
                            "color": "#d62728",
                            "label": "High utilization",
                            "value": 2
                        }
                    ],
                    "vertical": ${var.vertical_annotations}
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 24,
            "width": 24,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/RDS", "NetworkTransmitThroughput", "DBInstanceIdentifier", "${var.db_instance_identifier}", { "stat": "Maximum" } ],
                    [ ".", "NetworkReceiveThroughput", ".", ".", { "stat": "Maximum" } ]
                ],
                "region": "${var.region}",
                "yAxis": {
                    "left": {
                        "min": 0
                    },
                    "right": {
                        "min": 0
                    }
                },
                "title": "Network throughput",
                "annotations": {
                    "vertical": ${var.vertical_annotations}
                }
            }
        }
    ]
}
EOF

}

