/*
 * ## Example: 
 * ```hcl
 * module "lambda_insights" {
 *   source = github.com/18F/identity-terraform//lambda_insights?ref=main
 * }
 * ```
 */

locals {
  layer_arn = join(":", [
    "arn:${local.partition}:lambda:${var.region}:${var.lambda_insights_account}:layer",
    "LambdaInsightsExtension:${var.lambda_insights_version}"
  ])

  partition = contains(["us-gov-west-1"], data.aws_region.current.region) ? "aws-us-gov" : "aws"
}

data "aws_region" "current" {}

data "aws_iam_policy" "insights" {
  arn = "arn:${local.partition}:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}
