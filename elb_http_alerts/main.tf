variable "env_name" {
    description = "Environment name, for prefixing the generated metric names"
}

variable "load_balancer_id" {
    description = "ID of the IDP load balancer"
}

variable "alarm_actions" {
    type = "list"
    description = "A list of ARNs to notify when the ELB alarms fire"
}

resource "aws_cloudwatch_metric_alarm" "elb_http_5xx" {
    alarm_name = "${var.env_name} IDP ELB HTTP 5XX"
    alarm_description = "(Managed by Terraform) HTTP 5XX errors served by the ELB without the IDP"
    namespace = "AWS/ApplicationELB"
    metric_name = "HTTPCode_ELB_5XX_Count"
    dimensions {
      LoadBalancer = "${var.load_balancer_id}"
    }

    statistic = "Sum"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    threshold = 30
    period = 60
    datapoints_to_alarm = 1
    evaluation_periods = 1

    treat_missing_data = "missing"

    alarm_actions = "${var.alarm_actions}"
}

resource "aws_cloudwatch_metric_alarm" "target_http_5xx" {
    alarm_name = "${var.env_name} IDP Target HTTP 5XX"
    alarm_description = "(Managed by Terraform) HTTP 5XX errors served by IDP"
    namespace = "AWS/ApplicationELB"
    metric_name = "HTTPCode_Target_5XX_Count"
    dimensions {
      LoadBalancer = "${var.load_balancer_id}"
    }

    statistic = "Sum"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    threshold = 150
    period = 300
    evaluation_periods = 1

    treat_missing_data = "notBreaching"

    alarm_actions = "${var.alarm_actions}"
}
