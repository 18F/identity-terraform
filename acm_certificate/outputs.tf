output "cert_arn" {
  description = "ARN of the issued ACM certificate"
  value       = aws_acm_certificate.main.arn
}

output "finished_id" {
  description = "Reference this output in order to depend on validation being complete."
  value       = aws_acm_certificate_validation.main.id
}
