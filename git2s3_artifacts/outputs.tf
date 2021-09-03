output "output_bucket" {
  value = aws_s3_bucket_object.git2s3_output_bucket_name.key
}
