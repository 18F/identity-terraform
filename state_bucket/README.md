# `state_bucket`

This module creates and manages S3 buckets for AWS S3 Inventory (storage/configration) and S3 Logging, and (optionally) the Terraform remote state S3 bucket and remote state DynamoDB lock table.

## Example

```hcl
module "tf-state" {
  source = "github.com/18F/identity-terraform//state_bucket?ref=main"

  remote_state_enabled = 1
  region               = var.region
  bucket_name_prefix   = var.bucket_name_prefix
  sse_algorithm        = "AES256"
}
```

## Managing Remote State Configs From Within Terraform

***NOTE:** If choosing not to manage the S3 remote state bucket and DynamoDB lock table within Terraform, set the `remote_state_enabled` variable to **0**. Otherwise, read on!*

Traditionally, these are tricky resources to manage because there is a chicken and egg bootstrapping problem involved in creating them: Terraform needs the remote state bucket to exist before it runs for the first time, but we do want to manage this bucket *in* Terraform so that it doesn't diverge from the expected configuration (encryption, versioning, etc.).

Since version `4.x` of the AWS provider plugin, all of the attributes for an S3 bucket (aside from its name and its `prevent_destroy` lifecycle configuration) are configured within independent resources. As a result, Terraform can manage all of these attributes separately -- including adding and removing them, as required -- using the S3 bucket as a *data source* instead of a directly-managed resource. (The DynamoDB table will still need to be imported into state after creation.)

One possible way to do this, as it pertains to this module, is to create a script which will:

1. create the `tf-state` S3 bucket and `terraform_locks` DynamoDB table manually, i.e. with `aws-cli` operations / SDK API calls
2. set up a workspace using `terraform init` / `get`
3. run `import` to add the DynamoDB table to the remote state, e.g.:

  ```
  terraform import 'module.main.module.tf-state.aws_dynamodb_table.tf-lock-table[0]' 'terraform_locks'
  ```

Assuming that the names for the bucket and table match what the module thinks they should be (based on the `bucket_name_prefix` and `state_lock_table` variables), a subsequent `apply` operation should set the DynamoDB table in lockstep with the remote state, and should create the various S3 configuration resources associated with the `tf-state` bucket.

If desiring to *remove* these resources (e.g. when doing a complete infrastructure teardown), the simplest method would be to remove the entire module (or at least the `s3-access-logs` and `tf-lock-table` resources) from state, run a `destroy` operation, and then delete the remaining resources from AWS manually.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3_config"></a> [s3\_config](#module\_s3\_config) | github.com/18F/identity-terraform//s3_config | 91f5c8a84c664fc5116ef970a5896c2edadff2b1 |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.tf-lock-table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_s3_bucket.inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.s3-access-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.s3-access-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.tf-state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.s3-access-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_logging.tf-state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.s3-access-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.tf-state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.s3_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.tf_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.s3-access-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.tf-state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.s3-access-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.tf-state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.inventory_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_reject_non_secure_operations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_s3_bucket.tf-state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name_prefix"></a> [bucket\_name\_prefix](#input\_bucket\_name\_prefix) | First substring in S3 bucket name of $bucket\_name\_prefix.$bucket\_name.$account\_id-$region | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | n/a | yes |
| <a name="input_remote_state_enabled"></a> [remote\_state\_enabled](#input\_remote\_state\_enabled) | Whether to manage the remote state bucket<br>and DynamoDB lock table (1 for true, 0 for false). | `number` | `1` | no |
| <a name="input_sse_algorithm"></a> [sse\_algorithm](#input\_sse\_algorithm) | SSE algorithm to use to encrypt reports in S3 Inventory bucket. | `string` | `"aws:kms"` | no |
| <a name="input_state_lock_table"></a> [state\_lock\_table](#input\_state\_lock\_table) | Name of the DynamoDB table to use for state locking with the S3 state backend, e.g. 'terraform\_locks' | `string` | `"terraform_locks"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_inventory_bucket_arn"></a> [inventory\_bucket\_arn](#output\_inventory\_bucket\_arn) | n/a |
| <a name="output_s3_access_log_bucket"></a> [s3\_access\_log\_bucket](#output\_s3\_access\_log\_bucket) | n/a |
<!-- END_TF_DOCS -->
