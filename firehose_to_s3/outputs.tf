output "firehose_arn" {
    description = "Firehose arn"
    value = "${aws_kinesis_firehose_delivery_stream.kinesis_s3.arn}"
}