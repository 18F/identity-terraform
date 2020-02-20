# `iam_assumerole`

This Terraform module is designed to create all of the IAM resources necessary for cross-account AssumeRole access, via:

- a policy document dictating access via `statement{}` blocks
- a role that can be assumed by any IAM user in a 'master' account with access to assume that role (via user/group privileges)
- a policy created from the policy document
- an attachment of the role to the policy
- (optionally) additional attachment(s) if there are other IAM policies that should be attached to the assumable role
