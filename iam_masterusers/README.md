# `iam_masteruser`

This Terraform module can be used to create one or more IAM users.
Group memberships are assigned per-user for simpler user management.

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

`user_map` - Map with user name as key and a list of group memberships
             as the value.
