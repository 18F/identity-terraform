# `ssm`

This Terraform module is used to create `Command` and/or `Session` SSM Documents -- the latter of which can be `Standard_Stream`, `InteractiveCommands`, and/or `Port` Session docs -- for connecting to and running commands on AWS EC2 instances. Along with the documents themselves, this module creates:

1. An S3 bucket for storing output logs of SSM documents (see note below), configured using [the `s3_config` module](https://github.com/18F/identity-terraform/tree/main/s3_config) from this repo
2. A set of CloudWatch Log Groups recording each _invocation_ of a particular SSM document, for all SSM documents passed in with the various map vars
2. A second set of CloudWatch Log Groups recording the _output_ of any SSM documents, in any map var(s), where `logging = true`
3. A KMS key + alias for encrypting the above resources (logs/bucket/objects), as well as the SSM sessions themselves
4. An IAM policy document (as a `data` source) that can be attached to EC2 instances, providing access to SSM Control/Data Channels, S3/CloudWatch, and KMS encryption -- all necessary permissions for starting document-based SSM sessions

*NOTE: EC2 instances must have the [SSM Agent installed and configured](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-install-ssm-agent.html) in order to connect to them with the SSM documents created with this module.*

## Schema

SSM documents are created from individual object blocks within their respective `ssm_*_map` variable(s), e.g.:

```hcl
  ssm_session_doc_map = {
    "sudo" = {
      command     = "sudo su -"
      description = "Login and change to root user"
      logging     = false
    },
  }
```

In this example:

- As this is in the `ssm_session_doc_map` variable, the resulting SSM document will be named `<ENV>-ssm-session-sudo`
- Starting a session using this document is done via `aws ssm start-session --document <ENV>-ssm-session-sudo`
- SSM document output/session data will NOT be logged to the console, as `logging = false` (see note below)

## Optional: Logging SSM Sessions

Each document declared in each `ssm_*_map` variable has an option, `logging`, which specifies two things:

1. For _all_ documents across all map vars: whether or not to create CloudWatch Log Groups named `/aws/ssm/${var.env_name}/output/TYPE_DOCUMENT-NAME`
2. For `Standard_Session`/`InteractiveCommand`/`Port` (Session) documents: whether or not to log all console output within the actual SSM sessions themselves to their corresponding aforementioned Log Group(s)

When set to `true`, the following is included in the `inputs` section of the document content:

```yaml
s3BucketName: aws_s3_bucket.ssm_logs.id
s3EncryptionEnabled: true
s3KeyPrefix: output/TYPE_DOCUMENT-NAME
cloudWatchLogGroupName: aws_cloudwatch_log_group.ssm[output/TYPE_DOCUMENT-NAME].name
cloudWatchEncryptionEnabled: true
cloudWatchStreamingEnabled: true
```

If enabled, this means *everything* that is printed to the console, i.e. commands run, output/error output, etc. will be logged to S3 and CloudWatch Logs. As there may be cases where logging this data is undesirable -- e.g. when running commands on an instance that may print PII to the console -- this option can be set to `false`, which will change the above `inputs` to:

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

  ssm_session_doc_map = {
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
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.5 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_ssm_logs_bucket_config"></a> [ssm\_logs\_bucket\_config](#module\_ssm\_logs\_bucket\_config) | github.com/18F/identity-terraform//s3_config | 7a090cdc3647c08eb511b49e328caf33deef4f24 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_event_rule.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_kms_alias.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.ssm_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_ssm_document.cmd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.interactive](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.portforward](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.session](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_require_secure_connections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm_access_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name_prefix"></a> [bucket\_name\_prefix](#input\_bucket\_name\_prefix) | First substring in S3 bucket name of $bucket\_name\_prefix.$env\_name-ssm-logs.$account\_id-$region | `string` | n/a | yes |
| <a name="input_cloudwatch_retention_days"></a> [cloudwatch\_retention\_days](#input\_cloudwatch\_retention\_days) | Number of days to retain Streams for all CloudWatch Log Groups defined in/created by this module. | `number` | `365` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Environment name | `string` | n/a | yes |
| <a name="input_force_destroy_ssm_logs_bucket"></a> [force\_destroy\_ssm\_logs\_bucket](#input\_force\_destroy\_ssm\_logs\_bucket) | Allow destruction of the ssm\_logs S3 bucket, even if it contains objects. | `bool` | `false` | no |
| <a name="input_inventory_bucket_arn"></a> [inventory\_bucket\_arn](#input\_inventory\_bucket\_arn) | ARN of the S3 bucket used for collecting S3 Inventory reports. | `string` | n/a | yes |
| <a name="input_logging_bucket_id"></a> [logging\_bucket\_id](#input\_logging\_bucket\_id) | ID (name) of the S3 bucket used for logging S3 access events. | `string` | n/a | yes |
| <a name="input_prevent_tf_log_deletion"></a> [prevent\_tf\_log\_deletion](#input\_prevent\_tf\_log\_deletion) | Whether to ACTUALLY destroy CloudWatch Log Groups in this module vs. just removing them from state when using -destroy. | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region for the module. | `string` | `"us-west-2"` | no |
| <a name="input_s3_blocked_encryption_types"></a> [s3\_blocked\_encryption\_types](#input\_s3\_blocked\_encryption\_types) | Single-item list of SSE types to block for object uploads to the S3 bucket(s) in this module. | `list(string)` | <pre>[<br/>  "SSE-C"<br/>]</pre> | no |
| <a name="input_s3_bucket_key_enabled"></a> [s3\_bucket\_key\_enabled](#input\_s3\_bucket\_key\_enabled) | Whether or not to use a Bucket Key for the S3 bucket(s) in this module. | `bool` | `false` | no |
| <a name="input_session_timeout"></a> [session\_timeout](#input\_session\_timeout) | Amount of time (in minutes) of inactivity to allow before a session ends. | `number` | `15` | no |
| <a name="input_ssm_cmd_doc_map"></a> [ssm\_cmd\_doc\_map](#input\_ssm\_cmd\_doc\_map) | Map of data for SSM Command Documents. Each must map the document name to a description, the list of command(s) to run,<br/>any parameter(s) used to configure said command(s), and whether to create a CloudWatch Log Group for logging output(s)<br/>of said command(s) if `--cloud-watch-output-config` is passed into the `ssm send-command` operation. | <pre>map(object({<br/>    description = string<br/>    parameters = list(object({<br/>      name        = string<br/>      type        = string<br/>      description = string<br/>      pattern     = optional(string)<br/>      values      = optional(list(string))<br/>      default     = string<br/>    }))<br/>    command = list(string)<br/>    logging = bool<br/>  }))</pre> | `{}` | no |
| <a name="input_ssm_interactive_cmd_map"></a> [ssm\_interactive\_cmd\_map](#input\_ssm\_interactive\_cmd\_map) | Map of data for SSM InteractiveCommand Session Documents. Each must map the document name to a description,<br/>command(s) to run, any parameter(s) used to configure said command(s), whether or not to run the command(s) as root,<br/>and whether to log the output from the session to S3 + CloudWatch. | <pre>map(object({<br/>    description = string<br/>    parameters = optional(list(object({<br/>      name        = string<br/>      type        = string<br/>      description = string<br/>      pattern     = optional(string)<br/>      values      = optional(list(string))<br/>      default     = string<br/>    })))<br/>    command      = list(string)<br/>    run_elevated = bool<br/>    logging      = bool<br/>  }))</pre> | `{}` | no |
| <a name="input_ssm_portforward_cmd_map"></a> [ssm\_portforward\_cmd\_map](#input\_ssm\_portforward\_cmd\_map) | Map of data for SSM Port Forwarding Documents. Each must map the document name to a description, parameters for the<br/>session (portNumber, localPortNumber, and host), and whether to log the output from the session to S3 + CloudWatch. | <pre>map(object({<br/>    description = string<br/>    parameters = list(object({<br/>      name        = string<br/>      type        = string<br/>      description = string<br/>      pattern     = optional(string)<br/>      values      = optional(list(string))<br/>      default     = string<br/>    }))<br/>    logging = bool<br/>  }))</pre> | `{}` | no |
| <a name="input_ssm_session_doc_map"></a> [ssm\_session\_doc\_map](#input\_ssm\_session\_doc\_map) | Map of data for SSM Standard\_Stream Session Documents. Each must map the document name to a description, the command<br/>to run when connected (i.e. a shell to invoke), and whether to log the output from the session to S3 + CloudWatch. | <pre>map(object({<br/>    description = string<br/>    command     = string<br/>    logging     = bool<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ssm_access_role_policy"></a> [ssm\_access\_role\_policy](#output\_ssm\_access\_role\_policy) | Body of the ssm\_access\_role\_policy, in JSON |
| <a name="output_ssm_kms_arn"></a> [ssm\_kms\_arn](#output\_ssm\_kms\_arn) | ARN of the KMS key used for S3/session/log encryption. |
<!-- END_TF_DOCS -->