# `iam_assumerole`

This Terraform module is designed to create all of the IAM resources necessary for cross-account AssumeRole access, via:

- a role that can be assumed by any IAM user in a 'master' account with access to assume that role (via user/group privileges)
- one or more policy documents dictating access via `statement{}` blocks
- one or more policies created from the policy document(s)
- one or more attachments of the role to the policy(ies)
- (optionally) additional attachment(s) if there are other IAM policies that should be attached to the assumable role

Because Policy Documents have a size limit, it is often necessary to break policies up with multiple documents. Creating multiple policies and documents is possible using a `list(object)` variable in Terraform, which allows each object in the list to contain:

1. the policy name
2. the policy description
3. the policy document statement(s)

## Example

```hcl
locals {
  custom_policy_arns = [
    aws_iam_policy.rds_delete_prevent.arn,
    aws_iam_policy.region_restriction.arn,
  ]
  master_assumerole_policy = data.aws_iam_policy_document.master_account_assumerole.json
}

module "billing-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=main"

  role_name                = "BillingReadOnly"
  enabled                  = var.iam_billing_enabled
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "BillingReadOnly"
      policy_description = "Policy for reporting group read-only access to Billing ui"
      policy_document    = [
        {
          sid    = "BillingReadOnly"
          effect = "Allow"
          actions = [
            "aws-portal:ViewBilling",
          ]
          resources = [
            "*",
          ]
        },
      ]
    },
  ]
}
```

## Variables

- `enabled` - **bool**: Whether or not to create the role + policy + attachments. Used when declaring a role via a Terraform template which is NOT used across all accounts. Defaults to _true_.
- `role_name` - **string**: Name of the IAM role to be created.
- `role_duration` - **number**: Value of the `max_session_duration` for the role, in seconds. Defaults to _43200_ (12 hours).
- `master_assumerole_policy` - **object**: JSON object of the policy document to attach to the role allowing AssumeRole access from a master account. Pass in using `data.aws_iam_policy_document.<DATA_SOURCE_NAME>.json` as shown in the example above.
- `custom_policy_arns` - **list**: ARNs of any additional IAM policies to attach to the role.
- `iam_policies` - **list(object)**: List of objects, each of which contains:
   - `policy_name` - **string**: Name of the IAM policy to be created.
   - `policy_description` - **string**: Description of the IAM policy.
   - `policy_document` - **list(object)**: List of Statements included in the policy document. Each _object_ in the list should include the contents of a Statement, i.e. the `sid`, `effect`, `actions`, and `resources`.
