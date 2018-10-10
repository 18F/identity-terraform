# ASG Recycle

This module creates scheduled actions to change the desired count of an auto
scaling group. It is designed to provide for an automatic recycle of all
instances in the ASG by doubling the number of instances and then returning to
the original desired count. This works on ASGs that use an OldestInstance
termination policy.

It supports two default modes: a once/6hr recycle (default) or a once/business
day recycle. You can also pass through arbitrary cron expressions.
