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

Traditionally, these are tricky resources to manage because there is a chicken and egg bootstrapping problem involved in creating them: Terraform needs the remote state bucket to exist before it runs for the first time, but we do want to manage this bucket _in_ Terraform so that it doesn't diverge from the expected configuration (encryption, versioning, etc.).

Since version `4.x` of the AWS provider plugin, all of the attributes for an S3 bucket (aside from its name and its `prevent_destroy` lifecycle configuration) are configured within independent resources. As a result, Terraform can manage all of these attributes separately -- including adding and removing them, as required -- using the S3 bucket as a _data source_ instead of a directly-managed resource. (The DynamoDB table will still need to be imported into state after creation.)

One possible way to do this, as it pertains to this module, is to create a script which will:

1. create the `tf-state` S3 bucket and `terraform_locks` DynamoDB table manually, i.e. with `aws-cli` operations / SDK API calls
2. set up a workspace using `terraform init` / `get`
3. run `import` to add the DynamoDB table to the remote state, e.g.:
  ```
  terraform import 'module.main.module.tf-state.aws_dynamodb_table.tf-lock-table[0]' 'terraform_locks'
  ```

Assuming that the names for the bucket and table match what the module thinks they should be (based on the `bucket_name_prefix` and `state_lock_table` variables), a subsequent `apply` operation should set the DynamoDB table in lockstep with the remote state, and should create the various S3 configuration resources associated with the `tf-state` bucket.

If desiring to _remove_ these resources (e.g. when doing a complete infrastructure teardown), the simplest method would be to remove the entire module (or at least the `s3-access-logs` and `tf-lock-table` resources) from state, run a `destroy` operation, and then delete the remaining resources from AWS manually.

## Variables

`bucket_name_prefix` - First substring in S3 bucket name of `$bucket_name_prefix.$bucket_name.$account_id-$region`
`region` - AWS Region.
`remote_state_enabled` - Whether to manage the remote state bucket and DynamoDB lock table (1 for true, 0 for false).
`state_lock_table` - Name of the DynamoDB table to use for state locking with the S3 state backend, e.g. `terraform_locks`
`sse_algorithm` - SSE algorithm to use to encrypt reports in S3 Inventory bucket.