# `acm_certificate`

This Terraform module is a helper for issuing TLS certificates with Amazon Certificate Manager (ACM) using DNS (Route 53) validation.

Terraform syntax makes it very tricky to get this right when you have conditional resources or multiple subject alternative names.

## Example

```hcl
resource "aws_route53_zone" "default" {
  name = "example.com"
}

module "acm-cert" {
  source = "github.com/18F/identity-terraform//acm_certificate?ref=master"
  enabled = 1
  domain_name = "test.example.com"
  subject_alternative_names = [
    "alt1.example.com",
    "alt2.exampel.com",
  ]
  validation_zone_id = "${aws_route53_zone.default.zone_id}"
}

resource "aws_alb_listener" "ssl" {
  certificate_arn = "${module.acm-cert.cert_arn}"
  ...
}
```

## Variables

- `domain_name` - The primary domain name on the certificate
- `enabled` — Like count, but for the whole module. 1 for True, 0 for False
- `subject_alternative_names` — A list of additional names on the certificate
- `validation_zone_id` — Route53 zone for validation CNAMEs
- `validation_cname_ttl` — TTL for the validation CNAMEs

## Outputs

- `cert_arn` — ARN of the issued ACM certificate
- `finished_id` — Reference this output variable in order to depend on
  validation being complete. In TF 0.12 you can `depends_on` this variable
  directly, otherwise you may need a `null_resource`.

