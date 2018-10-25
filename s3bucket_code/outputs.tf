output "s3_bucket_name" {
    description = "S3 bucket name"
    value = "${aws_s3_bucket.bucket.id}"
}

output "s3_bucket_arn" {
    description = "S3 bucket arn"
    value = "${aws_s3_bucket.bucket.arn}"
}