# `git2s3_sync`

This module serves as a trimmed-down, Terraform-only version/replacement to the ["Git webhooks on the AWS Cloud" Quick Start Deployment](https://aws-quickstart.github.io/quickstart-git2s3/), a CloudFormation stack used to deploy a full set of infrastructure allowing syncing between a third-party repository and an S3 bucket.

Unlike [`git2s3_artifacts` (also found within this repo)](https://github.com/18F/identity-terraform/tree/main/git2s3_artifacts), which primarily serves as a 'wrapper' around the original Quick Start template with some additional resources, this module creates all necessary resources within Terraform (instead of CloudFormation), albeit with some additional streamlining and removal of components not currently in use by Login.gov's infrastructure:

1. Only 1 Lambda function from the original stack, `GitPullLambda` (here created by `module.lambda_git2s3`), is created in this module. It has been updated to support a `python3.12` runtime, and will (currently) _only_ work using a GitHub repo as its source, as the dozens of extra `try`/`except` blocks used to handle all possible repository key/value pairs have been removed. It will also _only_ validate a payload received from its API webhook source based on the `source-ip` of the event; support for using an API secret has been dropped, primarily as it was not used in the original `git2s3_artifacts` implementation.
2. The `CopyZips` Lambda function has been removed entirely. Its singular purpose was to copy the source code of all other Lambda functions from the Quick Start S3 bucket to an S3 bucket within the target account, and as [the original S3 path AND its replacement have both been deprecated](https://github.com/aws-ia/cfn-ps-git2s3?tab=readme-ov-file#deprecation-notice), it no longer functions properly to begin with. Similarly, the S3 bucket where said functions were copied -- along with the `DeleteBucketContents` Lambda function, which deletes said Lambda zips from said bucket -- have both been removed, as neither served any additional purpose outside of stack creation/deletion.
3. The `CreateSSHKey` Lambda function -- which served as a single-invocation function, used to create an SSH key pair that was stored in S3 -- has been removed entirely. Instead, an `ephemeral` resource, `ephemeraltls_private_key`, is used to create an SSH keypair and store its public/private key values in an AWS Secrets Manager secret, which can then be accessed by the CodeBuild project when it is triggered by the Lambda function in `module.lambda_git2s3`.

```terraform
module "git2s3_sync" {
  source = "github.com/18F/identity-terraform//git2s3_sync?ref="
  #source = "../../../../identity-terraform/git2s3_sync"

  prevent_tf_log_deletion = false

  git2s3_project_name = "git2s3-sync"
  external_account_ids = [
    "000011112222",
    "333344445555",
    "666677778888",
  ]

  bucket_name_prefix     = "login-gov"
  sse_algorithm_artifact = "AES256"
  sse_algorithm_output   = "AES256"
  ssh_key_secret_version = 1
}

```

***NOTE:*** Once this module has been deployed by Terraform, the following values will be available to plug into the GitHub repo that will be used as the sync source for the CodeBuild project created within this module:

1. **Public key for the SSH key pair**: Stored in AWS Secrets Manager as the `PUBLIC_KEY` entry in the SecretString of `aws_secretsmanager_secret.ssh_key_pair`. Obtainable from the command line via `aws secretsmanager get-secret-value --secret-id ${SECRET_ID} --query SecretString --output text | jq -r '.PUBLIC_KEY'` where `${SECRET_ID}` is the value of the `aws_secretsmanager_secret.ssh_key_pair.id` attribute.
2. **API Gateway webhook URL**: This is available as a Terraform output (`webhook_api_url`) with a value of `"${aws_api_gateway_stage.webhook_prod.invoke_url}/gitpull"`. In GitHub, this can be added to the desired source repo under **Settings > Webhooks > Add webhook**. The **Content type** MUST be set to `application/json`; SSL verification should be **Enabled**; and 'Just the `push` event' can be used as the trigger for the webhook.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |

## Providers

| Name (Source) | Version |
|------|---------|
| <a name="provider_aws"></a> **aws** ([`hashicorp/aws`](#provider\_aws)) | [>= 5.89.0](https://registry.terraform.io/providers/hashicorp/aws/5.89.0) |
| <a name="provider_github"></a> **github** ([`integrations/github`](#provider\_github)) | [>= 6.2.2](https://registry.terraform.io/providers/integrations/github/6.2.2) |
| <a name="provider_ephemeraltls"></a> **ephemeraltls** ([`lonegunmanb/ephemeraltls`](#provider\_ephemeraltls)) | [>= 0.1.0](https://registry.terraform.io/providers/lonegunmanb/ephemeraltls/0.1.0) |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambda_git2s3"></a> [lambda\_git2s3](#module\_lambda\_git2s3) | github.com/18F/identity-terraform//lambda_function | 026f69d0a5e2b8af458888a5f21a72d557bbe1fe |
| <a name="module_s3_config_artifact"></a> [s3\_config\_artifact](#module\_s3\_config\_artifact) | github.com/18F/identity-terraform//s3_config | cea57dfeaa2e437852ffa488606bf37f954dce12 |
| <a name="module_s3_config_codebuild_output"></a> [s3\_config\_codebuild\_output](#module\_s3\_config\_codebuild\_output) | github.com/18F/identity-terraform//s3_config | cea57dfeaa2e437852ffa488606bf37f954dce12 |

## Resources

| Name | Type |
|------|------|
| [ephemeraltls_private_key.git2s3](https://registry.terraform.io/providers/lonegunmanb/ephemeraltls/latest/docs/ephemeral-resources/private_key) | ephemeral resource |
| [aws_iam_role.api_webhook](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.api_webhook_push](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy.api_webhook_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_api_gateway_rest_api.webhook](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_deployment.webhook](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_stage.webhook_prod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_iam_role.codebuild_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.codebuild_base](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codebuild_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_cloudwatch_log_group.codebuild_git2s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_codebuild_project.git2s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_kms_key.ssh_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_alias.ssh_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_s3_bucket.artifact_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_ownership_controls.artifact_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_acl.artifact_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.artifact_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.artifact_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_policy.artifact_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket.codebuild_output](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_ownership_controls.codebuild_output](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_acl.codebuild_output](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.codebuild_output](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.codebuild_output](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_policy.codebuild_output](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_secretsmanager_secret.ssh_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.ssh_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_iam_policy_document.api_webhook_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.api_webhook_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_base](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_ssh_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [github_ip_ranges.ips](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/ip_ranges) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_iam_policy_document.artifact_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_output_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_artifact_bucket_name"></a> [artifact\_bucket\_name](#input\_artifact\_bucket\_name) | S3 bucket where public artifacts can be stored | `string` | `""` | no |
| <a name="input_output_bucket_name"></a> [output\_bucket\_name](#input\_output\_bucket\_name) | S3 bucket where CodeBuild uploads ZIP files upon finishing builds successfully | `string` | `""` | no |
| <a name="input_bucket_name_prefix"></a> [bucket\_name\_prefix](#input\_bucket\_name\_prefix) | First substring in names for `log_bucket` and `inventory_bucket` | `string` | N/A | yes |
| <a name="input_log_bucket_name"></a> [log\_bucket\_name](#input\_log\_bucket\_name) | Specific name of the S3 bucket used for S3 logging | `string` | `""` | no |
| <a name="input_inventory_bucket_name"></a> [inventory\_bucket\_name](#input\_inventory\_bucket\_name) | Specific name of the S3 bucket used for S3 Inventory reports | `string` | `""` | no |
| <a name="input_sse_algorithm_artifact"></a> [sse\_algorithm\_artifact](#input\_sse\_algorithm\_artifact) | SSE algorithm to use to encrypt objects in the artifact_bucket | `string` | `"aws:kms"` | no |
| <a name="input_sse_algorithm_output"></a> [sse\_algorithm\_output](#input\_sse\_algorithm\_output) | SSE algorithm to use to encrypt objects in the output_bucket | `string` | `"AES256"` | yes |
| <a name="input_cloudwatch_retention_days"></a> [cloudwatch\_retention\_days](#input\_cloudwatch\_retention\_days) | Number of days to retain CloudWatch Log Groups/Streams created by this module | `number` | `365` | yes |
| <a name="input_prevent_tf_log_deletion"></a> [prevent\_tf\_log\_deletion](#input\_prevent\_tf\_log\_deletion) | Whether or not to stop Terraform from destroying CloudWatch Logs vs. simply removing from state | `bool` | `true` | yes |
| <a name="input_external_account_ids"></a> [external\_account\_ids](#input\_external\_account\_ids) | AWS account IDs permitted access to artifacts_bucket and output_bucket | `list(string)` | N/A | yes |
| <a name="input_git2s3_project_name"></a> [git2s3\_project\_name](#input\_git2s3\_project\_name) | Main identifier used as the name for the CodeBuild project, git-pull Lambda function, and other resources | `string` | `"git2s3"` | no |
| <a name="input_allowed_ip_ranges"></a> [allowed\_ip\_ranges](#input\_allowed\_ip\_ranges) | IP CIDR blocks allowed for communication between API Gateway and source repo (will use GitHub IP ranges if not specified) | `string` | `""` | no |
| <a name="input_ssh_key_secret_version"></a> [ssh\_key\_secret\_version](#input\_ssh\_key\_secret\_version) | Version number (integer) of Secrets Manager secret containing SSH keypair | `number` | `1` | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_output_bucket"></a> [output\_bucket](#output\_output\_bucket) | Name of the S3 bucket where CodeBuild will upload ZIP files of the source repository |
| <a name="output_webhook_api_url"></a> [webhook\_api\_url](#output\_webhook\_api\_url) | Full URL of the API gateway webhook, including `/gitpull` path, used by source repository when sending payloads |
<!-- END_TF_DOCS -->
