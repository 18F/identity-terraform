# `iam_assumegroup`

This Terraform module can be used to create one or more IAM groups, along with attached group policies.
The design is calculated from a map of the groups, and per-"Account Type" access levels, supplied as input.

If Terraform is dependent upon the ARNs to be calculated outside of this module,
it will be stuck in a circular dependency loop.
Thus, the policy ARNs are created from the input map.

## Account Type

The "account type" concept allows for more granular control of permissions for IAM groups
across multiple categories -- or "types" -- of AWS accounts. As an example:

An organization has the following accounts:

1. Dev / Infrastructure
2. Dev / S3 Buckets
3. Prod / Infrastructure
4. Prod / S3 Buckets
5. Master

Each account has the same list of roles, e.g.: FullAdmin, PowerUser, ReadOnly, SOCAdmin.

Each IAM group within **Master**, created by this template,
can have account-category-specific access to specific roles, e.g.:

- Developers: FullAdmin / ReadOnly / PowerUser in Dev accounts, ReadOnly in Prod accounts, ReadOnly in Master account
- DevOps: FullAdmin in Dev accounts, FullAdmin in Prod accounts, FullAdmin in Master account
- SOC Leads: SOCAdmin in Dev accounts, SOCAdmin in Prod accounts, FullAdmin in Master account

## Example

```hcl
module "devops_group" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=master"
  
  group_role_map = {
    "appdev" = [
      { "PowerUser"         = [ "Sandbox" ] },
      { "ReadOnly"          = [ "Sandbox" ] }
    ],
    "devops" = [
      { "FullAdministrator" = [ "Prod", "Sandbox", "Master" ] },
      { "ReadOnly"          = [ "Prod", "Sandbox" ] },
      { "KMSAdministrator"  = [ "Sandbox" ] }
    ],
    "soc" = [
      { "SOCAdministrator"  = [ "Sandbox", "Prod", "Master" ] }
    ]
  }

  master_account_id = "111122223333"
}
```

## Variables

`master_account_id` - AWS account ID for the 'master' account, where this group and all IAM users live.
`group_role_map` - Multi-level map of groups -> roles -> accounts, with each *element* being a map of the format below:

```
{
  "GROUP" = [
    {
      "ROLE" = [
        "ACCOUNT_TYPE"
      ]
    }
  ]
}
```