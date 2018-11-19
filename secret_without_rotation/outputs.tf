output "id" {
    description = "Secret Id"
    value = "${aws_secretsmanager_secret.secret_with_rotation.id}"
}

output "arn" {
    description = "Secret arn"
    value = "${aws_secretsmanager_secret.secret_with_rotation.arn}"
}