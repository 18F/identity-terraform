output "arn" {
    description = "S3 server access logging bucket arn"
    value = "${aws_s3_bucket.bucket.arn}"
}

output "name" {
    description = "S3 server access logging bucket name"
    value = "${aws_s3_bucket.bucket.id}"
}

output "domain_name" {
    description = "S3 server access loggin bucket domain name"
    value = "${aws_s3_bucket.bucket_domain_name}"
}