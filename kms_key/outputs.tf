output "kms_key_arn" {
    description = "KMS key arn"
    value = "${aws_kms_key.key.arn}"
}
ß
output "kms_key_id" {
    description = "KMS key id"
    value = "${aws_kms_key.key.key_id}"
}

output "kms_key_alias" {
    description = "KMS key alias"
    value = "${aws_kms_key.key.alias}"
}