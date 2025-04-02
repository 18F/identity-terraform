output "output_bucket" {
  value = aws_s3_bucket.codebuild_output.id
}

output "webhook_api_url" {
  value = "${aws_api_gateway_stage.webhook_prod.invoke_url}/gitpull"
}

output "ssh_public_key" {
  value = jsondecode(aws_lambda_invocation.lambda_sshkey.result)["pub_key"]
}

