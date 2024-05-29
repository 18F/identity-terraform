output "codebuild_log_group" {
  description = "Name of the CloudWatch Log Group for the CodeBuild project."
  value       = aws_cloudwatch_log_group.codebuild.name
}
