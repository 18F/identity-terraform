# `iam_assumerole`

This Terraform module can be used to build all necessary resources for a policy-managed IAM Group, via:

- an IAM Group resource, made up of a list of the users in the group + a custom name
- ARN(s) for one or more Group Policies, built from a map of account types + roles per account type

If Terraform is dependent upon the ARNs to be calculated outside of this module, it will be stuck in a circular dependency loop. This is why the policy ARNs are created from the input variables.

## Account Type

The "account type" concept allows for more granular control of permissions for IAM groups across multiple categories -- or "types" -- of AWS accounts. As an example:

An organization has the following accounts:

1. Dev / Infrastructure
2. Dev / S3 Buckets
3. Prod / Infrastructure
4. Prod / S3 Buckets
5. Master

Each account has the same list of roles, e.g.: FullAdmin, PowerUser, ReadOnly, SOCAdmin.

Each IAM group within **Master**, created by this template, can have account-category-specific access to specific roles, e.g.:

- Developers: FullAdmin / ReadOnly / PowerUser in Dev accounts, PowerUser / ReadOnly in Prod accounts, ReadOnly in Master account
- DevOps: FullAdmin in Dev accounts, FullAdmin in Prod accounts, FullAdmin in Master account
- SOC Leads: SOCAdmin in Dev accounts, SOCAdmin in Prod accounts, FullAdmin in Master account

## Example

```hcl
module "devops_group" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=master"
  
  group_name = "devops-team"
  group_members = [
    aws_iam_user.wayne.name,
    aws_iam_user.daryl.name,
    aws_iam_user.katie.name,
    aws_iam_user.daniel.name,
  ]
  iam_group_roles = [
    {
      role_name = "FullAdministrator",
      account_types = [ 
        "Prod", "Sandbox", "Master"
      ]
    },
    {
      role_name = "ReadOnly",
      account_types = [ 
        "Prod", "Sandbox"
      ]
    },
    {
      role_name = "KMSAdmin",
      account_types = [ 
        "Sandbox"
      ]
    }
  ]
  master_account_id = var.master_account_id
}

```

## Variables

`group_name` - Name of the group to be created.
`master_account_id` - AWS account ID for the 'master' account, where this group and all IAM users live.
`group_members` - List of AWS IAM users to be added to the group.
`iam_group_roles` - Map of roles / account types the group has access to, where each key:value pair is `role_name`:`account_types` (string:list).