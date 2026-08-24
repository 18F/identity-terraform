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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.5 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.assumable](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachments_exclusive.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachments_exclusive) | resource |
| [aws_iam_policy.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_custom_iam_policies"></a> [custom\_iam\_policies](#input\_custom\_iam\_policies) | The names of any additional IAM policies to attach to the role. | `list(string)` | `[]` | no |
| <a name="input_iam_policies"></a> [iam\_policies](#input\_iam\_policies) | Lists of JSON content (.json attribute) of one or more aws\_iam\_policy\_document data sources. Each list of data sources<br/>is converted to an aws\_iam\_policy resource, attached as a managed policy to the assumable IAM role; as such, the total<br/>length of all minified-JSON versions of all documents must not exceed 6,144 characters (per policy, i.e. per list). | `list(list(string))` | n/a | yes |
| <a name="input_master_assumerole_policy"></a> [master\_assumerole\_policy](#input\_master\_assumerole\_policy) | Policy document to attach to the role allowing AssumeRole access from a 'master' account. | `string` | n/a | yes |
| <a name="input_permissions_boundary_policy_arn"></a> [permissions\_boundary\_policy\_arn](#input\_permissions\_boundary\_policy\_arn) | ARN of an externally-created IAM policy used as the Permissions Boundary for the IAM role. | `string` | `""` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | A description/summary of the IAM role being created. | `string` | `""` | no |
| <a name="input_role_duration"></a> [role\_duration](#input\_role\_duration) | Value for the max\_session\_duration for the role, in seconds. Defaults to 43200 (12h). | `number` | `43200` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of the IAM role. | `string` | n/a | yes |
| <a name="input_role_tags"></a> [role\_tags](#input\_role\_tags) | Tags to apply to the IAM role, if using any. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | n/a |
| <a name="output_role_unique_id"></a> [role\_unique\_id](#output\_role\_unique\_id) | n/a |
<!-- END_TF_DOCS -->
