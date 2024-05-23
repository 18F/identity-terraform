output "layer_arn" {
  description = "The insights lambda layer arn for attaching to aws_lambda_functions"
  value       = local.layer_arn
}

output "iam_policy_arn" {
  description = "The IAM Policy ARN for attaching to iam_roles for writing to insights"
  value       = data.aws_iam_policy.insights.arn
}
