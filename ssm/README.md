# `ssm`

This Terraform module is used to create SSM Documents for connecting to and running commands on AWS EC2 instances. Along with the documents themselves, this module creates:

1. An S3 bucket, and CloudWatch log group, for storing logs of SSM sessions (see note below) -- the S3 bucket is configured using [the `s3_config` module](https://github.com/18F/identity-terraform/tree/main/s3_config) from this repo
2. A second CloudWatch log group for logging when, and by whom, any given SSM document is used (via a CloudWatch event rule)
3. A KMS key + alias for encrypting the above resources (logs/bucket/objects), as well as the SSM sessions themselves
4. An IAM policy document (as a `data` source) that can be attached to EC2 instances, providing access to SSM Control/Data Channels, S3/CloudWatch, and KMS encryption -- all necessary permissions for starting document-based SSM sessions

*NOTE: EC2 instances must have the [SSM Agent installed and configured](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-install-ssm-agent.html) in order to connect to them with the SSM documents created with this module.*

## Schema

SSM documents are created from individual object blocks within the `ssm_doc_map` variable, e.g.:

```
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

If enabled, this means _everything_ that is printed to the console, i.e. commands run, output/error output, etc. will be logged to S3 and CloudWatch logs. As there may be cases where logging this data is undesirable -- e.g. when running commands on an instance that may print PII to the console -- this option can be set to `false`, which will change the above `inputs` to:

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
    },
    "tail-cw" = {
      command     = "sudo tail -f /var/log/cloud-init-output.log"
      description = "Tail the cloud-init-output logs"
      logging     = true
  }
}
```

## Variables

| Name                    | Type                 | Description                                                              | Required | Default                                                                                                                                                   |
| -----                   | -----                | -----                                                                    | -----    | -----                                                                                                                                                     |
| `ssm_doc_map`           | **map(map(string))** | Map of data for SSM documents                                            | YES      | <pre>{<br> 'default' = {<br>  description = 'Login shell'<br>  command   = 'cd ; /bin/bash'<br>  logging   = true<br>  use_root  = true<br> },<br>}</pre> |
| `session_timeout`       | **number**           | Amount of time (in minutes) of inactivity to allow before a session ends | YES      | 15                                                                                                                                                        |
| `region`                | **string**           | AWS Region                                                               | YES      |                                                                                                                                                           |
| `env_name`              | **string**           | Environment name                                                         | YES      |                                                                                                                                                           |
| `bucket_name_prefix`    | **string**           | First substring in S3 bucket name                                        | YES      |                                                                                                                                                           |
| `log_bucket_name`       | **string**           | Override name of the bucket used for S3 logging                          | NO       | <blank>                                                                                                                                                   |
| `inventory_bucket_name` | **string**           | Override name of the S3 bucket used for S3 Inventory reports             | NO       | <blank>                                                                                                                                                   |
