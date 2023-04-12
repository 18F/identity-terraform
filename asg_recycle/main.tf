locals {
  schedule_map = var.custom_schedule == {} ? local.rotation_schedules : var.custom_schedule
  schedule = lookup(
    { for k, v in local.schedule_map : k => v if k == var.scale_schedule },
    var.scale_schedule
  )
}

resource "aws_autoscaling_schedule" "recycle_spinup" {
  for_each = toset(local.schedule["recycle_up"])

  scheduled_action_name = join(".", [
    "auto-recycle.spinup",
    index(local.schedule["recycle_up"], each.key)
  ])
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.normal_desired * var.spinup_mult_factor
  recurrence             = each.key
  time_zone              = var.time_zone
  autoscaling_group_name = var.asg_name
}

resource "aws_autoscaling_schedule" "recycle_spindown" {
  for_each = toset(local.schedule["recycle_down"])

  scheduled_action_name = join(".", [
    "auto-recycle.spindown",
    index(local.schedule["recycle_down"], each.key)
  ])
  min_size = var.min_size
  max_size = var.max_size
  desired_capacity = var.override_spindown_capacity == -1 ? (
  var.normal_desired) : var.override_spindown_capacity
  recurrence             = each.key
  time_zone              = var.time_zone
  autoscaling_group_name = var.asg_name
}

# Spin down to var.zero_size hosts, on a regular schedule. Depending upon selection,
# do this either daily after working hours, weekly (same time), or nightly.
# Follow a similar schedule to the recycle one above.
# Ensure that ASG can spin down/up, instead of capping min/max at var.zero_size hosts.

resource "aws_autoscaling_schedule" "autozero_spinup" {
  for_each = toset(local.schedule["autozero_up"])

  scheduled_action_name = join(".", [
    "auto-zero.spinup",
    index(local.schedule["autozero_up"], each.key)
  ])
  min_size = var.normal_min
  max_size = var.normal_max == var.zero_size ? (
  var.normal_min == var.zero_size ? 1 : var.normal_min) : var.normal_max
  desired_capacity = (
    var.normal_desired > var.normal_max || var.normal_desired < var.normal_min ? (
    var.normal_max) : var.normal_desired
  )
  recurrence             = each.key
  time_zone              = var.time_zone
  autoscaling_group_name = var.asg_name
}

resource "aws_autoscaling_schedule" "autozero_spindown" {
  for_each = toset(local.schedule["autozero_down"])

  scheduled_action_name = join(".", [
    "auto-zero.spindown",
    index(local.schedule["autozero_down"], each.key)
  ])
  min_size               = var.zero_size
  max_size               = var.max_size
  desired_capacity       = var.zero_size
  recurrence             = each.key
  time_zone              = var.time_zone
  autoscaling_group_name = var.asg_name
}
