variable "asg_name" {
  description = "Name of the Auto Scaling Group to apply scheduled actions to."
  type        = string
}

variable "override_spindown_capacity" {
  description = <<EOM
Set a specific number of instances for spindown instead of normal_desired.
Will ONLY override the Desired capacity for the auto-recycle.spindown action.
EOM
  type        = number
  default     = -1
}

variable "max_size" {
  description = "Default maximum capacity for the Auto Scaling Group."
  type        = number
  default     = -1
}

variable "min_size" {
  description = "Default minimum capacity for the Auto Scaling Group."
  type        = number
  default     = -1
}

variable "normal_desired" {
  description = <<EOM
Default Desired capacity for the Auto Scaling Group.
Multiplied by spinup_mult_factor to set the Desired capacity for auto-recycle.spinup.
Used for auto-recycle.spindown, unless override_spindown_capacity has been set.
EOM
  type        = number
}

variable "normal_max" {
  description = "Normal (post-autozero) maximum capacity for the Auto Scaling Group."
  type        = number
}

variable "normal_min" {
  description = "Normal (post-autozero) minimum capacity for the Auto Scaling Group."
  type        = number
}

variable "spinup_mult_factor" {
  description = <<EOM
Multiplier for normal_desired to calculate Desired capacity (normal x mult)
for the auto-recycle.spinup scheduled action.
EOM
  type        = number
  default     = 2
}

variable "time_zone" {
  description = "IANA time zone to use with cron schedules. Uses UTC by default."
  type        = string
  default     = "Etc/UTC"
}

variable "scale_schedule" {
  description = <<EOM
Name of one of the blocks defined in schedule.tf, which defines the cron schedules
for recycling and/or 'autozero' scheduled actions. MUST match one of the key names
in local.rotation_schedules (or var.custom_schedule if using that instead).
EOM
  type        = string
  default     = "nozero_norecycle"
}

variable "custom_schedule" {
  description = <<EOM
Customized set of cron jobs for recycling (up/down) and/or zeroing out hosts.
MUST contain at least one object with var.scale_schedule as its name, and
MUST follow the defined format as shown for the default value!
EOM
  type        = any
  default = {
    #   "custom_schedule" = {
    #     recycle_up    = ["0 11 * * 1-5"]
    #     recycle_down  = ["15 11 * * 1-5"]
    #     autozero_up   = ["0 5 * * 1-5"]
    #     autozero_down = ["0 17 * * 1-5"]
    #   }
  }
}
