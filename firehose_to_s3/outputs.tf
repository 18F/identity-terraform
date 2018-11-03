output "firehose_arn" {
    description = "Firehose arn"
    value = "${aws_kinesis_firehose_delivery_stream.kinesis_s3.arn}"
}

output "firehose_role_arn" {
    description = "Arn for IAM Role assigned to Firehose"
    value = "${aws_iam_role.firehose_to_s3.arn}"
}