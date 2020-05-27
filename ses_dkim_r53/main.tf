# -- Variables --

variable "domain" {
  description = "Name of the owned/managed domain."
  type        = string
  default     = "example.com"
}

variable "zone_id" {
  description = "ID for the Route53 zone where the domain exists."
  type        = string
  default     = "ABCDEFGHIJ123"
}

variable "manual_verification_token" {
  description = "SES verification token, if previously created outside of Terraform"
  type        = string
  default     = ""
}

variable "manual_dkim_tokens" {
  description = "SES DKIM tokens, if previously created outside of Terraform"
  type        = list(any)
  default     = []
}

variable "ttl_verification_record" {
  description = "TTL value for the SES verification TXT record."
  type        = string
  default     = "1800"
}

variable "ttl_dkim_records" {
  description = "TTL value for the SES DKIM records."
  type        = string
  default     = "1800"
}

# -- Resources --

resource "aws_ses_domain_identity" "primary" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "primary" {
  domain = "${aws_ses_domain_identity.primary.domain}"
}

resource "aws_route53_record" "primary_verification_record" {
  zone_id = var.zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = var.ttl_verification_record
  records = ["${var.manual_verification_token != "" ? var.manual_verification_token : aws_ses_domain_identity.example.verification_token}"]
}

resource "aws_route53_record" "primary_ses_dkim" {
  count   = 3
  zone_id = var.zone_id
  name    = "${element(var.manual_dkim_tokens != "" ? var.manual_dkim_tokens : aws_ses_domain_dkim.primary.dkim_tokens, count.index)}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = var.ttl_dkim_records
  records = ["${element(var.manual_dkim_tokens != "" ? var.manual_dkim_tokens : aws_ses_domain_dkim.primary.dkim_tokens, count.index)}.dkim.amazonses.com"]
}
