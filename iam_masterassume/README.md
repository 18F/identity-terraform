# `iam_masterassume`

This Terraform module creates IAM policies, and associated policy documents, allowing groups/users in a 'master' AWS account to assume roles in other accounts.

## Account Type

The "account type" concept allows for more granular control of permissions for IAM groups across multiple categories -- or "types" -- of AWS accounts. As an example:

An organization has the following accounts:

1. Dev / Infrastructure
2. Dev / S3 Buckets
3. Prod / Infrastructure
4. Prod / S3 Buckets
5. Master

Each account has the same list of roles, e.g.: FullAdmin, PowerUser, ReadOnly, SOCAdmin.

1. 3 AWS accounts for development
2. 2 accounts for production
3. 1 account for 'master'

A module can be added to the Terraform configuration for each "type" of account, which will create all necessary IAM policies (and documents) to allow AssumeRole access for each Role to all accounts within that "type".

## Example

```hcl
module "assume_roles_prod" {
  source = "github.com/18F/identity-terraform//iam_masterassume?ref=master"

  role_list = [
    "FullAdministrator",
    "PowerUser",
    "ReadOnly",
    "BillingReadOnly",
    "ReportsReadOnly",
    "KMSAdministrator",
    "SOCAdministrator",
  ]
  account_type = "Prod"
  account_numbers = [
    "111111111111",
    "222222222222"
  ]
}

```

## Variables

- `account_type`: The "type", aka "category", of AWS account(s) that this module will create policies for.
- `account_numbers`: A list of AWS account number(s) within the `account_type` category.
- `role_list`: A list of the roles available to be assumed from within the account(s).