output "output_bucket" {
  value = aws_s3_bucket.codebuild_output.id
}

output "webhook_api_url" {
  value = "${aws_api_gateway_stage.webhook_prod.invoke_url}/gitpull"
}
