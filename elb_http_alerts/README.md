# `elb_http_alerts`

This Terraform module uses AWS-provided metrics from Load Balancers, and creates CloudWatch alarms for HTTP/5XX errors. It supports both Classic and Application Load Balancers, and creates alarms for both the Load Balancer itself and for attached targets/instances.

## Example

```hcl
module "elb_http_alerts" {
  source = "github.com/18F/identity-terraform//elb_http_alerts?ref=main"

  env_name = var.env_name
  lb_name  = aws_alb.idp.name
  lb_type  = "ALB"

  // These are defined in variables.tf
  alarm_actions = local.high_priority_alarm_actions
}
```

## Variables

- `env_name` - Environment name, for prefixing the generated metric names.
- `lb_name` - Name of the Load Balancer.
- `lb_type` - Type of Load Balancer (ELB or ALB).
- `alarm_actions` - A list of ARNs to notify when the LB alarms fire.
- `lb_threshold` - Number of errors to trigger LB 5xx alarm.
- `target_threshold` - Number of errors to trigger targets/instances 5xx alarm.