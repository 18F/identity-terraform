# `asg_recycle`

This Terraform module is used to create automatic tasks that 'recycle' and/or 'zero out' the EC2 instances in an Auto Scaling Group (ASG), via a set of Scheduled Actions applied to the group. These tasks are defined thusly:

- ***Recycling*** involves doubling the Desired count of an ASG, allowing new instances to spin up, and then resetting the Desired count back to its original value after a specific number of minutes.
- ***Zeroing out*** involves setting the Desired count of an ASG to 0 at a specified time, which is useful for spinning down hosts on a daily/nightly/weekly/etc. basis when they will not be in use.

Since the goal of these Scheduled Actions is to replace older EC2 instances with newer ones, this module *only* works on ASGs that use an `OldestInstance` termination policy.

## Schedules

Within `schedule.tf` is a local variable, `rotation_schedules`, which is a map of predefined schedules for recycling and/or zeroing out hosts, based on common scaling needs for ASGs:

- `*zero` schedules define how frequently (if at all) 'zero out' actions are run; the actions they create will spin up instances at 0500 and spin them down to 0 at 1600
- `norecycle` schedules do not create 'recycle' actions, regardless of whether or not 'zero out' actions are also created
- `normal` schedules create 4 'recycle' actions every day (at 0500 / 1100 / 1700 / 2300)
- `business` schedules create a single 'recycle' action each weekday (at 1700)
- For schedules that call for both types of actions, any times normally used by the 'recycle' schedule are instead used by the 'zero out' schedule (in order to prevent overlapping/duplicate Scheduled Actions)

The `cron` expressions for the predefined schedules are as follows:

| Schedule Name           | Recycle UP Schedule                                                 | Recycle DOWN Schedule                                                  | Zero-Out UP Schedule | Zero-Out DOWN Schedule |
| ----------              | ----------                                                          | ----------                                                             | ----------           | ----------             |
| `nozero_norecycle`      | N/A                                                                 | N/A                                                                    | N/A                  | N/A                    |
| `nozero_normal`         | `0 5,11,17,23 * * *`                                                | `15 5,11,17,23 * * *`                                                  | N/A                  | N/A                    |
| `nozero_business`       | `0 17 * * 1-5`                                                      | `15 17 * * 1-5`                                                        | N/A                  | N/A                    |
| `dailyzero_norecycle`   | N/A                                                                 | N/A                                                                    | `0 5 * * 1-5`        | `0 17 * * 1-5`         |
| `dailyzero_normal`      | `0 11 * * 1-5`                                                      | `15 11 * * 1-5`                                                        | `0 5 * * 1-5`        | `0 17 * * 1-5`         |
| `dailyzero_business`    | N/A                                                                 | N/A                                                                    | `0 5 * * 1-5`        | `0 17 * * 1-5`         |
| `nightlyzero_norecycle` | N/A                                                                 | N/A                                                                    | `0 5 * * 1-5`        | `0 21 * * 1-5`         |
| `nightlyzero_normal`    | `0 11,17 * * 1-5`                                                   | `15 11,17 * * 1-5`                                                     | `0 5 * * 1-5`        | `0 21 * * 1-5`         |
| `nightlyzero_business`  | `0 17 * * 1-5`                                                      | `15 17 * * 1-5`                                                        | `0 5 * * 1-5`        | `0 21 * * 1-5`         |
| `weeklyzero_norecycle`  | N/A                                                                 | N/A                                                                    | `0 5 * * 1`          | `0 17 * * 5`           |
| `weeklyzero_normal`     | <pre>0 11,17,23 * * 1<br>0 5,11,17,23 * * 2-4<br>0 5,11 * * 5</pre> | <pre>15 11,17,23 * * 1<br>15 5,11,17,23 * * 2-4<br>15 5,11 * * 5</pre> | `0 5 * * 1`          | `0 17 * * 5`           |
| `weeklyzero_business`   | `0 17 * * 1-4`                                                      | `15 17 * * 1-4`                                                        | `0 5 * * 1`          | `0 17 * * 5`           |

If desiring to use a different set of expressions for 'recycle' and/or 'zero out' schedules, `var.custom_schedule` can be used instead, e.g.:

```terraform
custom_schedule = {
  "asg_rotation_schedule" = {
    recycle_up    = ["0 11 * * 1-5"]
    recycle_down  = ["15 11 * * 1-5"]
    autozero_up   = ["0 5 * * 1-5"]
    autozero_down = ["0 17 * * 1-5"]
  }
}
```

To use a set of expressions, set `var.scale_schedule` to the name of the desired schedule, and the module will extract its corresponding 'recycle'/'zero out' schedules from the `local.rotation_schedules` map in `schedule.tf` (or `var.custom_schedule`, if using that instead).

## Examples

Using one of the schedules from `local.rotation_schedules` / `schedules.tf`:

```terraform
module "idp_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=main"

  asg_name                = aws_autoscaling_group.idp.name
  normal_desired_capacity = aws_autoscaling_group.idp.desired_capacity
  scale_schedule          = "nightlyzero_business"
}
```

Using `var.custom_schedule` and overrides for the multiplier, timezone, and spindown capacity:

```terraform
module "migration_recycle" {
  source = "github.com/18F/identity-terraform//asg_recycle?ref=main"

  asg_name                   = aws_autoscaling_group.migration.name
  normal_desired_capacity    = 1
  time_zone                  = "America/New_York"
  spinup_mult_factor         = 1
  override_spindown_capacity = 0
  scale_schedule             = "migration_nightlyzero_business"
  custom_schedule = {
    "migration_nightlyzero_business" = {
      recycle_up   = ["50 16 * * 1-5"]
      recycle_down = ["20 17 * * 1-5"]
      autozero_up  = ["50 4 * * *"]
      autozero_down = [
        "20 5 * * *",
        "50 20 * * *"
      ]
    }
  }
}
```

## Variables

| Name                         | Type    | Description                                                                                                                           | Required | Default            |
| ----                         | ----    | -----------                                                                                                                           | -------- | -------            |
| `asg_name`                   | string  | Name of the Auto Scaling Group to apply scheduled actions to                                                                          | YES      | N/A                |
| `normal_desired_capacity`    | number  | Default Desired capacity for the Auto Scaling Group                                                                                   | YES      | N/A                |
| `override_spindown_capacity` | number  | Set a specific number of instances for spindown instead of `normal_desired_capacity`                                                  | NO       | -1                 |
| `max_size`                   | number  | Default maximum capacity for the Auto Scaling Group                                                                                   | NO       | -1                 |
| `min_size`                   | number  | Default minimum capacity for the Auto Scaling Group                                                                                   | NO       | -1                 |
| `spinup_mult_factor`         | number  | Multiplier for `normal_desired_capacity` to calculate Desired capacity (normal x mult) for the `auto-recycle.spinup` scheduled action | NO       | 2                  |
| `time_zone`                  | string  | IANA time zone to use with cron schedules (uses UTC by default)                                                                       | NO       | Etc/UTC            |
| `scale_schedule`             | string  | Name of a block in `local.rotation_schedules` or `var.custom_schedule` with `cron` schedules for the associated Scheduled Actions     | NO       | `nozero_norecycle` |
| `custom_schedule`            | `any`   | Customized set of cron jobs for recycling (up/down) and/or zeroing out hosts (overrides `local.rotation_schedules` if set)            | NO       | {}                 |
