output "lambda_arn" {
    description = "Lambda arn"
    value = "${aws_lambda_function.lambda.arn}"
}