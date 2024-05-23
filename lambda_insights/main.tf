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
    "arn:aws:lambda:${var.region}:${var.lambda_insights_account}:layer",
    "LambdaInsightsExtension:${var.lambda_insights_version}"
  ])
}

data "aws_iam_policy" "insights" {
  arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}
