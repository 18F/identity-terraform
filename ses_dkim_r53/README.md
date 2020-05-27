# `ses_dkim_r53`

Given a domain name and a Route53 zone ID, this Terraform module will create:

- an SES identity resource for the provided domain + corresponding Route53 TXT verification record
- three (3) SES domain DKIM generation resources for the provided domain + corresponding Route53 CNAME records

## Example

```hcl
module "core_ses" {
  source = "github.com/18F/identity-terraform//ses_dkim_r53?ref=master"

  domain                    = var.root_domain
  zone_id                   = module.common_dns.primary_zone_id
  ttl_verification_record   = "1800"
  ttl_dkim_records          = "1800"
}
```

## Variables

- `domain` - Name of the owned/managed domain.
- `zone_id` - ID for the Route53 zone where the domain exists.
- `ttl_verification_record` - TTL value for the SES verification TXT record. Defaults to ***1800***.
- `ttl_dkim_records` - TTL value for the SES DKIM records. Defaults to ***1800***.