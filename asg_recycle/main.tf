locals {
  schedule_map = var.custom_schedule == {} ? local.rotation_schedules : var.custom_schedule
  schedule = lookup(
    { for k, v in local.schedule_map : k => v if k == var.scale_schedule },
    var.scale_schedule
  )
}

resource "aws_autoscaling_schedule" "recycle_spinup" {
  for_each = toset(local.schedule["recycle_up"])

  scheduled_action_name  = "auto-recycle.spinup"
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.normal_desired * var.spinup_mult_factor
  recurrence             = each.key
  time_zone              = var.time_zone
  autoscaling_group_name = var.asg_name
}

resource "aws_autoscaling_schedule" "recycle_spindown" {
  for_each = toset(local.schedule["recycle_down"])

  scheduled_action_name = "auto-recycle.spindown"
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity = var.override_spindown_capacity == -1 ? (
  var.normal_desired) : var.override_spindown_capacity
  recurrence             = each.key
  time_zone              = var.time_zone
  autoscaling_group_name = var.asg_name
}

# Spin down to 0 hosts, on a regular schedule. Depending upon selection,
# do this either daily after working hours, weekly (same time), or nightly.
# Follow a similar schedule to the recycle one above.
# Ensure that ASG can spin down/up, instead of capping min/max at 0 hosts.

resource "aws_autoscaling_schedule" "autozero_spinup" {
  for_each = toset(local.schedule["autozero_up"])

  scheduled_action_name = "auto-zero.spinup"
  min_size              = var.min_size
  max_size = var.max_size == 0 ? (
  var.min_size == 0 ? 1 : var.min_size) : var.max_size
  desired_capacity = (
    var.normal_desired > var.max_size || var.normal_desired < var.min_size ? (
    var.max_size) : var.normal_desired
  )
  recurrence             = each.key
  time_zone              = var.time_zone
  autoscaling_group_name = var.asg_name
}

resource "aws_autoscaling_schedule" "autozero_spindown" {
  for_each = toset(local.schedule["autozero_down"])

  scheduled_action_name  = "auto-zero.spindown"
  min_size               = 0
  max_size               = var.max_size
  desired_capacity       = 0
  recurrence             = each.key
  time_zone              = var.time_zone
  autoscaling_group_name = var.asg_name
}
