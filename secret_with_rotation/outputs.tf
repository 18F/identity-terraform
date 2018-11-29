output "id" {
    description = "Secret Id"
    value = "${aws_secretsmanager_secret.secret_with_rotation.id}"
}

output "arn" {
    description = "Secret arn"
    value = "${aws_secretsmanager_secret.secret_with_rotation.arn}"
}

output "lambda_arn" {
    description = "Rotation lambda arn"
    value = "${aws_lambda_function.lambda.arn}"
}

output "lambda_role_arn" {
    description = "Rotation lambda role arn"
    value = "${aws_iam_role.lambda.arn}"
}

output "lambda_role_id" {
    description = "Rotation lambda role id"
    value = "${aws_iam_role.lambda.unique_id}"
}

output "lambda_role_name" {
    description = "Rotation lambda role name"
    value = "${aws_iam_role.lambda.name}"
}

output "lambda_security_group_id" {
    description = "Security Group Id for rotation lambda"
    value = "${aws_security_group.lambda.id}"
}