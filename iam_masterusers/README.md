# `iam_masteruser`

This Terraform module can be used to create one or more IAM users.
Group memberships are assigned per-user for simpler user management.

An IAM policy called ***ManageYourAccount*** will also be created,
which is attached to all users in `user_map`. It allows each user
basic access to configure their own account, i.e. updating their own
password, adding an MFA device, etc., and sets an explicit **Deny** on
numerous actions -- *including* `sts:AssumeRole` -- if the user does
not have an MFA device configured.

## Example

```hcl
module "our_cool_master_users" {
  source = "github.com/18F/identity-terraform//iam_masterusers?ref=master"
  
  user_map = {
    'fred.flinstone' = ['development'],
    'barny.rubble' = ['devops'],
    'space.ghost' = ['devops', 'host'],
  }
}
```

## Variables

`user_map` - Map with user name as key and a list of group memberships as the value.
`group_depends_on` - Can be used to wait for the groups in `user_map` to ACTUALLY exist
before attempting to create the group memberships.
