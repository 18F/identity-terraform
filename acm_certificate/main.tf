# Create the certificate with the specified SubjectAltNames
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create each validation CNAME
resource "aws_route53_record" "validation-cnames" {
  for_each = {
    for item in aws_acm_certificate.main.domain_validation_options: item.domain_name => {
      name   = item.resource_record_name
      record = item.resource_record_value
      type   = item.resource_record_type
    }
  }

  name            = each.value.name
  type            = each.value.type
  zone_id         = var.validation_zone_id
  records         = [each.value.record]
  ttl             = var.validation_cname_ttl
  allow_overwrite = true
}

# Synthetic Terraform resource that blocks on validation completion
# You can depend_on this to wait for the ACM cert to be ready.
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.validation-cnames: record.fqdn]
}

