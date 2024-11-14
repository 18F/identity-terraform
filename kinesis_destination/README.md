# `kinesis_destination`

This module creates and manages a CloudWatch Logs Destination, which is used to send data to an externally-created Kinesis resource (either a Data Stream or a Firehose delivery stream) in the same account. It also adds an IAM policy to the Destination so that CloudWatch Subscription Filters can be pointed to it (both individual and account-level Subscription Filters), allowing any number of log groups to send to the same Kinesis resource.

Both the Kinesis resource _and_ the Destination(s) must be in the same _account_. However, this module may be called multiple times to create additional CloudWatch Logs Destinations in separate _regions_, if desired.

## Example

```hcl
#### Kinesis Data Stream already created in us-west-2 ####

# create Destination in us-west-2 that accepts Subscription Filters/Logs from two AWS accounts
module "kinesis_stream_destination_uw2" {
  source = "github.com/18F/identity-terraform//kinesis_destination?ref=main"
  providers = {
    aws = aws.usw2
  }

  kinesis_arn        = aws_kinesis_stream.logarchive.arn
  source_account_ids = ["111111111111", "222222222222"]
}

# create Destination in us-east-1 which points to Firehose in us-west-2, logging only one AWS account
module "kinesis_firehose_destination_ue1" {
  source = "github.com/18F/identity-terraform//kinesis_destination?ref=main"
  providers = {
    aws = aws.use1
  }

  kinesis_arn        = aws_kinesis_firehose_delivery_stream.logarchive.arn
  source_account_ids = ["111111111111"]
}
```

## Variables

| Name                 | Type         | Description                                                                                                                                      | Required | Default |
| ---------------      | ------       | -------------------------------------------------------------------------------------------                                                      | -------- | ------- |
| `kinesis_arn`        | string       | ARN of the Kinesis resource (Firehose/Data Stream) that the Destination points to.                                                               | YES      | N/A     |
| `source_account_ids` | list(string) | ID(s) of the AWS Account(s) where log data will be sent FROM.                                                                                    | YES      | N/A     |
| `role_name`          | string       | Identifier string used to name the IAM role/policies and the CloudWatch Destination itself (uses `"cloudwatch-to-kinesis-${REGION}"` if not set) | NO       | `""`    |

## Outputs

| Name                      | Description                                                      | Value                                        |
| -----                     | -----                                                            | -----                                        |
| `kinesis_destination_arn` | ARN of the CloudWatch Logs Destination for the Kinesis resource. | `aws_cloudwatch_log_destination.kinesis.arn` |
