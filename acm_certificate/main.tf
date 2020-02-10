# -- Variables --

variable "domain_name" {
  description = "The primary name used on the issued TLS certificate"
}

# TODO: convert to bool
variable "enabled" {
  default     = 1
  description = "Like count, but for the whole module. 1 for True, 0 for False."
}

variable "subject_alternative_names" {
  default     = []
  description = "A list of additional names to add to the certificate"
}

variable "validation_enabled" {
  default     = 1
  description = "If ACM certificates are provisioned across multiple regions, \
  only 1 set of records is required"
}

variable "validation_zone_id" {
  description = "Zone ID used to create the validation CNAMEs"
}

variable "validation_cname_ttl" {
  default = 300
}

# -- Outputs --

output "cert_arn" {
  description = "ARN of the issued ACM certificate"
  value       = element(concat(aws_acm_certificate.main.*.arn, [""]), 0)
}

output "finished_id" {
  description = "Reference this output in order to depend on validation being complete."
  value       = element(concat(aws_acm_certificate_validation.main.*.id, [""]), 0)
}

# -- Resources --

# Create the certificate with the specified SubjectAltNames
resource "aws_acm_certificate" "main" {
  count = var.enabled

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true

    # TODO: this is a workaround for an AWS API / Terraform AWS provider bug
    # https://github.com/terraform-providers/terraform-provider-aws/issues/8531
    # https://github.com/18F/identity-devops/issues/1469
    ignore_changes = [subject_alternative_names]
  }
}

# Create each validation CNAME
resource "aws_route53_record" "validation-cnames" {
  count = var.validation_enabled == 1 ? length(var.subject_alternative_names) + 1 : 0

  name    = aws_acm_certificate.main[0].domain_validation_options[count.index]["resource_record_name"]
  type    = aws_acm_certificate.main[0].domain_validation_options[count.index]["resource_record_type"]
  zone_id = var.validation_zone_id
  records = [aws_acm_certificate.main[0].domain_validation_options[count.index]["resource_record_value"]]
  ttl     = var.validation_cname_ttl
}

# Synthetic Terraform resource that blocks on validation completion
# You can depend_on this to wait for the ACM cert to be ready.
resource "aws_acm_certificate_validation" "main" {
  count = var.validation_enabled

  certificate_arn = aws_acm_certificate.main[0].arn

  validation_record_fqdns = aws_route53_record.validation-cnames.*.fqdn
}

