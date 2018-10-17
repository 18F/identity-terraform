output "kms_key_arn" {
    description = "KMS key arn"
    value = "${aws_kms_key.key.arn}"
}

output "kms_key_id" {
    description = "KMS key id"
    value = "${aws_kms_key.key.key_id}"
}

output "kms_key_alias_arn" {
    description = "KMS key alias arn"
    value = "${aws_kms_alias.alias.arn}"
}