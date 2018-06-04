# Create two lifecycle hooks for the specified Auto Scaling Group that hook
# into instance launches. By default, these will be called provision-main
# and provision-private.

variable "asg_name" {
	description = "Name of the auto scaling group that we're adding lifecycle hooks to."
}

variable "lifecycle_name_prefix" {
  description = "Prefix for the lifecycle hook names"
  default = "provision"
}

variable "main_hook_enabled" {
  description = "Whether to create the $prefix-main lifecycle hook"
  default = 1
}
variable "private_hook_enabled" {
  description = "Whether to create the $prefix-private lifecycle hook"
  default = 1
}

variable "main_heartbeat_timeout" {
  description = "How long to wait before the main lifecycle hook times out"
  default = 1800 # 30 minutes
}
variable "private_heartbeat_timeout" {
  description = "How long to wait before the private lifecycle hook times out"
  default = 900 # 15 minutes
}

resource "aws_autoscaling_lifecycle_hook" "provision-private" {
  count                  = "${var.private_hook_enabled}"
  name                   = "${var.lifecycle_name_prefix}-private"
  autoscaling_group_name = "${var.asg_name}"
  default_result         = "ABANDON"
  heartbeat_timeout      = "${var.private_heartbeat_timeout}"
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

resource "aws_autoscaling_lifecycle_hook" "provision-main" {
  count                  = "${var.main_hook_enabled}"
  name                   = "${var.lifecycle_name_prefix}-main"
  autoscaling_group_name = "${var.asg_name}"
  default_result         = "ABANDON"
  heartbeat_timeout      = "${var.main_heartbeat_timeout}"
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

output "lifecycle_hook_names" {
  value = [
    "${aws_autoscaling_lifecycle_hook.provision-private.name}",
    "${aws_autoscaling_lifecycle_hook.provision-main.name}"
  ]
}
