# `ssm`

This Terraform module is used to create `Standard_Session`, `Command`, and/or `InteractiveCommand` SSM Documents for connecting to and running commands on AWS EC2 instances. Along with the documents themselves, this module creates:

1. An S3 bucket, and CloudWatch log group, for storing logs of SSM sessions (see note below) -- the S3 bucket is configured using [the `s3_config` module](https://github.com/18F/identity-terraform/tree/main/s3_config) from this repo
2. A second CloudWatch log group for logging when, and by whom, any given SSM document is used (via a CloudWatch event rule)
3. A KMS key + alias for encrypting the above resources (logs/bucket/objects), as well as the SSM sessions themselves
4. An IAM policy document (as a `data` source) that can be attached to EC2 instances, providing access to SSM Control/Data Channels, S3/CloudWatch, and KMS encryption -- all necessary permissions for starting document-based SSM sessions

*NOTE: EC2 instances must have the [SSM Agent installed and configured](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-install-ssm-agent.html) in order to connect to them with the SSM documents created with this module.*

## Schema

SSM documents are created from individual object blocks within the `ssm_*_map` variable, e.g.:

```hcl
    "sudo" = {
      command     = "sudo su -"
      description = "Login and change to root user"
      logging     = false
    },
```

In this example:

- The resulting SSM document will be named `<ENV>-ssm-document-sudo`
- Starting a session using this document is done via `aws ssm start-session --document <ENV>-ssm-document-sudo`
- Session data will NOT be logged to the console, as `logging = false` (see note below)

## Optional: Logging SSM Sessions

Each document declared in `ssm_doc_map` has an option, `logging`, which specifies whether or not to log the actual SSM sessions themselves. When set to `true`, the following is included in the `inputs` section of the document content:

```yaml
s3BucketName: "${aws_s3_bucket.ssm_logs.id}"
s3EncryptionEnabled: true
cloudWatchLogGroupName: "${aws_cloudwatch_log_group.ssm_session_logs.name}"
cloudWatchEncryptionEnabled: true
cloudWatchStreamingEnabled: true
```

If enabled, this means *everything* that is printed to the console, i.e. commands run, output/error output, etc. will be logged to S3 and CloudWatch logs. As there may be cases where logging this data is undesirable -- e.g. when running commands on an instance that may print PII to the console -- this option can be set to `false`, which will change the above `inputs` to:

```yaml
s3EncryptionEnabled: false
cloudWatchEncryptionEnabled: false
```

In particular, `logging` should almost always be set to `false` for any SSM documents that start an interactive session/drop the user into a shell.

## Example

```hcl
module "ssm" {
  source = "github.com/18F/identity-terraform//ssm?ref=main"

  bucket_name_prefix = "login-gov"
  region             = var.region
  env_name           = var.env_name

  ssm_doc_map = {
    "default" = {
      command     = "/bin/bash"
      description = "Default shell to login"
      logging     = false
    },
    "sudo" = {
      command     = "sudo su -"
      description = "Login and change to root user"
      logging     = false
    }
  }
}
```
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
| <a name="module_ssm_logs_bucket_config"></a> [ssm\_logs\_bucket\_config](#module\_ssm\_logs\_bucket\_config) | github.com/18F/identity-terraform//s3_config | 91f5c8a84c664fc5116ef970a5896c2edadff2b1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.ssm_cmd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ssm_cmds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.ssm_cmd_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.ssm_session_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_kms_alias.kms_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.kms_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_ssm_document.ssm_cmd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.ssm_interactive_cmd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.ssm_portforward_cmd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.ssm_session](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_require_secure_connections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm_access_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name_prefix"></a> [bucket\_name\_prefix](#input\_bucket\_name\_prefix) | REQUIRED. First substring in S3 bucket name of<br/>$bucket\_name\_prefix.$env\_name-ssm-logs.$account\_id-$region | `string` | n/a | yes |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | REQUIRED. Environment name | `string` | n/a | yes |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | (OPTIONAL) Allow destruction of the ssm\_logs S3 bucket, even if it contains objects. | `bool` | `false` | no |
| <a name="input_inventory_bucket_name"></a> [inventory\_bucket\_name](#input\_inventory\_bucket\_name) | (OPTIONAL) Override name of the S3 bucket used for S3 Inventory reports.<br/>Will default to $bucket\_name\_prefix.s3-inventory.$account\_id-$region<br/>if not explicitly declared. | `string` | `""` | no |
| <a name="input_log_bucket_name"></a> [log\_bucket\_name](#input\_log\_bucket\_name) | (OPTIONAL) Override name of the bucket used for S3 logging.<br/>Will default to $bucket\_name\_prefix.s3-access-logs.$account\_id-$region<br/>if not explicitly declared. | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | REQUIRED. AWS Region | `string` | n/a | yes |
| <a name="input_session_timeout"></a> [session\_timeout](#input\_session\_timeout) | REQUIRED. Amount of time (in minutes) of inactivity<br/>to allow before a session ends. | `number` | `15` | no |
| <a name="input_ssm_cmd_doc_map"></a> [ssm\_cmd\_doc\_map](#input\_ssm\_cmd\_doc\_map) | REQUIRED. Map of data for SSM Command Documents. Each must include the document name,<br/>description, command to run, any parameter(s) used to configure said command, and<br/>whether to log the commands/output from the given session/document. | `map(any)` | <pre>{<br/>  "uptime": {<br/>    "command": [<br/>      "uptime"<br/>    ],<br/>    "description": "Verify host uptime",<br/>    "logging": false,<br/>    "parameters": []<br/>  }<br/>}</pre> | no |
| <a name="input_ssm_doc_map"></a> [ssm\_doc\_map](#input\_ssm\_doc\_map) | REQUIRED. Map of data for SSM Session Documents. Each must include the document name,<br/>description, command(s) to run at login, and whether to log the commands/output<br/>from the given session/document. | `map(map(string))` | <pre>{<br/>  "default": {<br/>    "command": "cd ; /bin/bash",<br/>    "description": "Login shell",<br/>    "exit": true,<br/>    "logging": false<br/>  }<br/>}</pre> | no |
| <a name="input_ssm_interactive_cmd_map"></a> [ssm\_interactive\_cmd\_map](#input\_ssm\_interactive\_cmd\_map) | REQUIRED. Map of data for SSM InteractiveCommand Session Documents. Each must<br/>include the document name, description, command to run, and any parameter(s) used<br/>to configure said command. | `map(any)` | <pre>{<br/>  "ifconfig": {<br/>    "command": [<br/>      "ifconfig"<br/>    ],<br/>    "description": "Check network interface configuration",<br/>    "parameters": []<br/>  }<br/>}</pre> | no |
| <a name="input_ssm_portforward_cmd_map"></a> [ssm\_portforward\_cmd\_map](#input\_ssm\_portforward\_cmd\_map) | REQUIRED. Map of data for SSM Port Forwarding Documents. Each must<br/>include the document name, description, command to run, and any parameter(s) used<br/>to configure said command. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ssm_access_role_policy"></a> [ssm\_access\_role\_policy](#output\_ssm\_access\_role\_policy) | Body of the ssm\_access\_role\_policy, in JSON |
| <a name="output_ssm_cmd_logs"></a> [ssm\_cmd\_logs](#output\_ssm\_cmd\_logs) | Name of the CloudWatch Log Group for SSM command logging. |
| <a name="output_ssm_kms_arn"></a> [ssm\_kms\_arn](#output\_ssm\_kms\_arn) | ARN of the KMS key used for S3/session/log encryption. |
| <a name="output_ssm_session_logs"></a> [ssm\_session\_logs](#output\_ssm\_session\_logs) | Name of the CloudWatch Log Group for SSM access logging. |
<!-- END_TF_DOCS -->
