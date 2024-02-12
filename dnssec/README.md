# `dnssec`

<!-- MarkdownTOC -->

- [Overview](#overview)
- [Enabling DNSSEC Signing with a KSK](#enabling-dnssec-signing-with-a-ksk)
- [KSK Key Rotation](#ksk-key-rotation)
- [The Future: Resource Protection Using Lifecycle Rules](#the-future-resource-protection-using-lifecycle-rules)
  - [Recommended: IAM Policy to Prevent Deletion/Disablement Of Resources](#recommended-iam-policy-to-prevent-deletiondisablement-of-resources)
- [Example Implementation](#example-implementation)
- [Variables](#variables)
  - [CloudWatch Alarm Description Fill-Ins](#cloudwatch-alarm-description-fill-ins)
  - [Other Variables](#other-variables)

<!-- /MarkdownTOC -->

## Overview

This module is used to create and enable DNSSEC configuration for a given domain (i.e. a hosted zone in Route 53). It creates:

- a KMS key + alias, used as a key-signing key (KSK) for DNSSEC -- currently (as of 2021-12-14) created _only_ in the `us-east-1` region
- an 'enable DNSSEC signing' resource, the actual AWS resource that sits on a hosted zone and allows DNSSEC signing to be configured / a DS record to be obtained
- an (optional) IAM policy which _prevents_ premature deletion/disabling/etc. of the KSK/KMS key(s), the DNSSEC-enabled resource, or the hosted zone itself
- CloudWatch Alarms to notify about DNSSEC errors, expiring KSKs, and other KSK-related alerts

More info about how DNSSEC management and KSKs work in AWS can be found in the [Configuring DNSSEC Signing](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec.html) section of AWS' Route 53 Developer Guide.

## Enabling DNSSEC Signing with a KSK

1. `apply` this module to enable DNSSEC signing for a hosted zone, and create a KMS-key-backed-KSK for said DNSSEC signing. You'll get the necessary values to create a DS record in the parent hosted zone from the Outputs, e.g. (using fake digest values here):
  ```bash
  primary_zone_active_ds_value = "12345 13 2 0000111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFF"
  primary_zone_dnssec_ksks = tomap({
    "20211006" = tomap({
      "digest_algorithm" = "SHA-256"
      "digest_value" = "0000111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFF"
      "ds_record" = "12345 13 2 0000111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFF"
      "signing_algorithm" = "ECDSAP256SHA256"
    })
  })
  ```
2. With the `ds_record` info above, [establish a chain of trust](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec-enable-signing.html#dns-configuring-dnssec-chain-of-trust) with your parent hosted zone in order to create a DS record. You may need to supply the `digest_algorithm`, `signing_algorithm`, and `digest_value` values separately, depending upon your registrar. 
3. Once the updates have propagated (based upon the TTL for your domain record), you can verify that DNSSEC signing has been enabled, and is configured correctly in a few different ways:
  - Use [DNSViz](https://dnsviz.net/) to verify the trust chain and see a visual representation of it, from the parent hosted zone to individual records (such as `AAAA`, `MX`, etc.) within your hosted zone
  - `dig a DOMAINNAMEHERE +dnssec @9.9.9.10` - check if DNSSEC is validating using a non-validating cache (`ad` should be in the `flags` section)
  - `dig DNSKEY DOMAINNAMEHERE +short` - look up the current KSK and ZSKs (KSK have a code of 257 and ZSK have a code of 256)

## KSK Key Rotation

1. The `dnssec_ksks` variable is a string map used to configure the KSKs for any given hosted zone, and for allow for easier rotation of said keys when required ([a best practice with regard to cryptographic keys in general, as well.](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec-ksk.html#dns-configuring-dnssec-ksk-delete-ksk)):
  ```hcl
    dnssec_ksks = {
      # 20211005" = "old",
      "20211006" = "active"
    }
  ```
  It defaults to having _one_ value, as Route 53 / AWS will complain if you attempt to build 2 at the same time:
  ```bash
  Error: error creating Route 53 Key Signing Key: ConcurrentModification: Database is currently busy. Please retry.
  ```
2. To add a new key, uncomment the `"old"` line in the `var.dnssec_ksks` map, changing the date (i.e. `"2111005"`) to the date you are creating this new key (to help keep track of the lifetime of your keys). e.g.:
  ```hcl
    dnssec_ksks = {
      "20221005" = "active",
      "20211006" = "active"
    }
  ```
3. `apply`-ing this will generate another block in the `primary_zone_dnssec_ksks` output with the values for a new DS record. With this information in hand, you can follow the process above to _update_ the DS record (created with your parent hosted zone) to contain the digest/algorithm values of the new key.
4. Once the DS record and DNSSEC signing have been updated with the values from the new key -- and the changes have propagated -- you can comment out the now-unused key, change its value to `"old"` and the new one to `"active"`, and then `apply` the changes to deactivate and delete the old key, e.g.:
  ```hcl
    dnssec_ksks = {
      "20221005" = "active",
      # "20211006" = "old"
    }
  ```

## The Future: Resource Protection Using Lifecycle Rules

The possibility of accidental destruction of the 'DNSSEC-signing-enabled' resource, the KSK(s)/KMS key(s), and/or the Hosted Zone itself, is much higher when using Terraform or another third-party (i.e. non-AWS) tool to manage infrastructure (as critical warnings about such actions appear through AWS services, such as the console, but not in response to API calls made by Terraform). *This precise destruction -- via Terraform, in fact! -- [caused a minor, but long lasting, Slack outage in September 2021](https://slack.engineering/what-happened-during-slacks-dnssec-rollout/), even after extensive DNSSEC testing/prep on their part.*

However, for this module, the `lifecycle { prevent_destroy = true }` safeguard is **not** attached to the various DNSSEC resources. Doing so would add significant complexity, and manual work, to the key rotation process, as explained below:

Key rotation requires the ability to destroy the old, deactivated keys once they are fully confirmed to no longer be in use, and [lifecycle rules currently (as of 2022-08-11) do not support interpolation.](https://www.terraform.io/docs/language/meta-arguments/lifecycle.html#literal-values-only) Thus, logic cannot be written to change a lifecycle rule automatically when marking a key as inactive / commenting out a key in the `dnssec_ksks` string map. One would need to manually override/comment out the `lifecycle` block (in a local copy of `main.tf`), or remove it from the actual Terraform statefile (via `state pull` / `state push` commands), and run an *extra* `terraform apply` command, in order to remove the resources and keep Terraform's state accurate.

Until such time that they *can* be configured with interpolation, the `lifecycle` blocks for these resources are commented out, with the hope to include them as an additional safeguard in the future. Terraform *has* indicated an intent to implement this feature request in the near future, and further discussion and planning can be found within the `hashicorp/terraform` repo:
- https://github.com/hashicorp/terraform/issues/3116
- https://github.com/hashicorp/terraform/issues/30937

### Recommended: IAM Policy to Prevent Deletion/Disablement Of Resources

While the resources for KMS/KSK keys, aliases, and DNSSEC status itself don't currently have lifecycle blocks applied, we instead recommend creating and implmenting an IAM policy that uses an explicit **Deny** against any actions that could delete/disable the resources involved in this module, i.e.:

- deactivation/deletion of KSK(s) / the respective KMS key(s)
- disabling DNSSEC signing
- deleting the Hosted Zone itself

This IAM policy can then be attached to roles/users/groups as desired -- as an example, it could be one of the `custom_policy_arns` used when [creating roles via the `iam_assumerole` module (also in this repo!)](https://github.com/18F/identity-terraform/tree/main/iam_assumerole)

For even MORE protection, that policy CAN include a `lifecycle { prevent_destroy = true }` rule. Using this will require an additional Terraform operation to reverse said lifecycle rule if needing to delete the policy. This is an extra safeguard to help prevent resource removals/deletions, and you may want to still leave it in place even if/when lifecycle rule interpolation in Terraform is supported.

## Example Implementation

In `module/main.tf`:

```hcl
locals {
  dnssec_runbook_prefix = ": https://identityexampledomain.com/wiki/Runbook:DNS#dnssec"
}

module "dnssec" {
  source = "github.com/18F/identity-terraform//dnssec?ref=main"
  #source = "../../../../identity-terraform/dnssec"

  dnssec_ksks_action_req_alarm_desc = "${local.dnssec_runbook_prefix}_ksks_action_req"
  dnssec_ksk_age_alarm_desc         = "${local.dnssec_runbook_prefix}_ksk_age"
  dnssec_errors_alarm_desc          = "${local.dnssec_runbook_prefix}_errors"
  dnssec_zone_name                  = var.root_domain
  dnssec_zone_id                    = module.common_dns.primary_zone_id
  alarm_actions                     = [module.sns_slack.sns_topic_arn]
  dnssec_ksks                       = var.dnssec_ksks
}
```

In an environment-specific `main.tf`:

```hcl
module "main" {
  source = "../module"

  root_domain = identityexampledomain.gov
  dnssec_ksks = {
      # 20211005" = "old",
      "20211006" = "active"
  }
```

## Variables

### CloudWatch Alarm Description Fill-Ins

As DNSSEC and proper key rotation can often be complex processes to follow -- often with a significant timespan between rotations -- we recommend using this `README` file, and/or other DNSSEC literature, as a guide for creating runbooks/documentation/etc. for team members who may be responsible for these resources. To help increase visibility of said documentation, the following variables are available to add additional content to the description of each corresponding CloudWatch Alarm:

- `dnssec_ksks_action_req_alarm_desc`
- `dnssec_ksk_age_alarm_desc`
- `dnssec_errors_alarm_desc`

The implementation above uses a `local` variable, `dnssec_runbook_prefix`, to add links to the description of each alarm; These links point to different sections of the runbook that describe the alarms. As an example:

- With `dnssec_errors_alarm_desc` unset:
  ```
  alarm_description = "DNSSEC encountered 1+ errors in <24h"
  ```
- With `dnssec_errors_alarm_desc` set with the above example value/`local`:
  ```
  alarm_description = "DNSSEC encountered 1+ errors in <24h: https://identityexampledomain.com/wiki/Runbook:DNS#dnssec_errors"
  ```

### Other Variables

`alarm_actions` - A list of ARNs to notify via the CloudWatch Alarms, i.e. SNS topics.
`dnssec_ksk_max_days` - Maximum allowed age of a DNSSEC KSK before triggering a CloudWatch alarm.
`dnssec_ksks` - Map of Key Signing Keys (KSKs) to provision for each hosted zone.
`dnssec_zone_name` - Name of the Route53 DNS domain where DNSSEC signing will be enabled.
`dnssec_zone_id` - ID of the Route53 DNS domain where DNSSEC signing will be enabled.
