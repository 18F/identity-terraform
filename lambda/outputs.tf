output "lambda_arn" {
    description = "Lambda arn"
    value = "${aws_lambda_function.lambda.arn}"
}

output "lambda_role_arn" {
    description = "Arn for IAM Role assigned to Lambda"
    value = "${aws_iam_role.lambda.arn}"
}

output "lambda_role_name" {
    description = "Name of IAM Role assigned to Lambda"
    value = "${aws_iam_role.lambda.name}"
}

output "lambda_role_id" {
    description = "Unique id for role"
    value = "${aws_iam_role.lambda.unique_id}"
}