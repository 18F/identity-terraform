output "kms_key_arn" {
    description = "KMS key arn"
    value = "${aws_kms_key.key.arn}"
}

output "kms_key_key_id" {
    description = "KMS key id"
    value = "${aws_kms_key.key.key_id}"
}