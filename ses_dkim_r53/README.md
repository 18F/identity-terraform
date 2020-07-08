# `ses_dkim_r53`

Given a domain name and a Route53 zone ID, this Terraform module will create:

- an SES identity resource for the provided domain + corresponding Route53 TXT verification record
- three (3) SES domain DKIM generation resources for the provided domain + corresponding Route53 CNAME records

***NOTE:*** To allow for multi-region support, a `aws_route53_record.primary_verification_record` resource must be created separately (i.e. in the parent module), which uses the output value `ses_token` from each instance of `aws_ses_domain_identity.primary`.

## Example

```hcl
module "core_ses" {
  source = "github.com/18F/identity-terraform//ses_dkim_r53?ref=master"

  domain                    = var.root_domain
  zone_id                   = module.common_dns.primary_zone_id
  ttl_dkim_records          = "1800"
}
```

## Variables

- `domain` - Name of the owned/managed domain.
- `zone_id` - ID for the Route53 zone where the domain exists.
- `ttl_dkim_records` - TTL value for the SES DKIM records. Defaults to ***1800***.