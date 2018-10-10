output "kinesis_stream_arn" {
    description = "Arn for the Kinesis stream"
    value = "${aws_kinesis_stream.datastream.arn}"
}

output "kinesis_stream_name" {
    description = "Name of the Kinesis stream"
    value = "${aws_kinesis_stream.datastream.name}"
}