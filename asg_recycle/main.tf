# Remove this variable when modules support count
# https://github.com/hashicorp/terraform/issues/953
variable "enabled" {
    default = 1
    description = "Whether this module is enabled (hack around modules not supporting count)"
}

variable "asg_name" {
    description = "Name of the auto scaling group to recycle"
}

variable "normal_desired_capacity" {
    description = ""
}

variable "max_size" {
    # in TF 0.10 you can leave this as the default
    default = -1
}

variable "min_size" {
    # in TF 0.10 you can leave this as the default
    default = -1
}

variable "spinup_mult_factor" {
    default = 2
    description = "Multiple of normal_desired_capacity to spin up"
}

variable "spinup_recurrence" {
    default = ""
    description = "Spinup times in cron format, sets aws_autoscaling_schedule.spinup.recurrence"
}
variable "spindown_recurrence" {
    default = ""
    description = "Spindown times in cron format, sets aws_autoscaling_schedule.spindown.recurrence"
}

variable "use_daily_business_hours_schedule" {
    default = 0
    description = "If set to 1, recycle once per business day rather than the every-six-hour default"
}

# This block defines the actual default spinup/spindown schedule.
# If use_daily_business_hours_schedule is enabled, from Mon-Fri spin up at 1700
# UTC and spin down at 1800 UTC. Otherwise recycle every 6 hours every day by default.
locals {
    default_spinup_recurrence   = "${var.use_daily_business_hours_schedule == 1 ? "0 17 * * 1-5" : "0 5,11,17,23 * * *"}"
    default_spindown_recurrence = "${var.use_daily_business_hours_schedule == 1 ? "0 18 * * 1-5" : "0 6,12,18,0 * * *"}"
}

# Default schedule unless spinup_recurrence / spindown_recurrence are overridden:
# Spin up happens at   0500, 1100, 1700, 2300 UTC.
# Spin down happens at 0600, 1200, 1800, 0000 UTC.
#
# If IdP bootstrapping were faster (i.e. we reduce the ALB health check grace
# period time), we can reduce the interval between spinup and spindown.

# EST times (UTC-5):
# Spin up at   12a, 6a, 12p, 6p EST
# Spin down at  1a, 7a,  1p, 7p EST

# EDT times (UTC-4):
# Spin up at   1a, 7a, 1p, 7p EDT
# Spin down at 2a, 8a, 2p, 8p EDT

# PST times (UTC-8):
# Spin up at   3a, 9a,  3p, 9p  PST
# Spin down at 4a, 10a, 4p, 10p PST

# PDT times (UTC-7):
# Spin up at   4a, 10a, 4p, 10p PDT
# Spin down at 5a, 11a, 5p, 11p PDT

resource "aws_autoscaling_schedule" "spinup" {
    count = "${var.enabled}"

    scheduled_action_name  = "auto-recycle.spinup"
    min_size               = "${var.min_size}"
    max_size               = "${var.max_size}"
    desired_capacity       = "${var.normal_desired_capacity * var.spinup_mult_factor}"
    recurrence             = "${var.spinup_recurrence != "" ? var.spinup_recurrence : local.default_spinup_recurrence}"
    autoscaling_group_name = "${var.asg_name}"
}

resource "aws_autoscaling_schedule" "spindown" {
    count = "${var.enabled}"

    scheduled_action_name  = "auto-recycle.spindown"
    min_size               = "${var.min_size}"
    max_size               = "${var.max_size}"
    desired_capacity       = "${var.normal_desired_capacity}"
    recurrence             = "${var.spindown_recurrence != "" ? var.spindown_recurrence : local.default_spindown_recurrence}"

    autoscaling_group_name = "${var.asg_name}"
}
