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
    value = "${module.password_rotation_lambda.lambda_arn}"
}

output "lambda_role_arn" {
    description = "Rotation lambda role arn"
    value = "${module.password_rotation_lambda.lambda_role_arn}"
}

output "lambda_role_id" {
    description = "Rotation lambda role id"
    value = "${module.password_rotation_lambda.lambda_role_id}"
}