output "id" {
    description = "Secret Id"
    value = "${aws_secretsmanager_secret.secret_without_rotation.id}"
}

output "arn" {
    description = "Secret arn"
    value = "${aws_secretsmanager_secret.secret_without_rotation.arn}"
}