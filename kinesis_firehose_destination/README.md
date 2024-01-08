# `kinesis_firehose_destination`

This module creates and manages a CloudWatch Logs Destination, which is used to send data to an externally-created Kinesis Data Firehose delivery stream (in any region). It also adds an IAM policy to the Destination so that CloudWatch Subscription Filters can be pointed to it, allowing any number of log groups -- from multiple regions, if this module is called for each one -- to send to the same Kinesis Data Firehose, if desired.

## Example

```hcl
#### Kinesis Data Firehose already created in us-west-2 ####

# create Destination in us-west-2
module "logarchive_uw2" {
  source = "github.com/18F/identity-terraform//kinesis_firehose_destination?ref=main"

  firehose_arn     = aws_kinesis_firehose_delivery_stream.logarchive.arn
  source_account_id = "111111111111"
}

# create Destination in us-east-1 which points to Firehose in us-west-2
module "logarchive_ue1" {
  source = "github.com/18F/identity-terraform//kinesis_firehose_destination?ref=main"
  providers = {
    aws = aws.use1
  }

  firehose_arn     = aws_kinesis_firehose_delivery_stream.logarchive.arn
  firehose_region   = "us-west-2"
  source_account_id = "111111111111"
}
```

## Variables

| Name                | Type   | Description                                                                                 | Required | Default |
| ---------------     | ------ | ------------------------------------------------------------------------------------------- | -------- | ------- |
| `firehose_arn`      | string | ARN of the Kinesis Data Firehose where data will be sent.                                   | YES      | N/A     |
| `firehose_region`   | string | Region where the Kinesis Data Firehose is located.                                          | NO       | `""`    |
| `source_account_id` | string | ID of the AWS Account where log data will be sent FROM.                                     | YES      | N/A     |
| `role_name`         | string | Identifier string used to name the IAM role/policies and the CloudWatch Destination itself. | NO       | `""`    |

## Outputs

| Name                       | Description                                                  | Value                                         |
| -----                      | -----                                                        | -----                                         |
| `firehose_destination_arn` | ARN of the CloudWatch Logs Destination for Kinesis Firehose. | `aws_cloudwatch_log_destination.firehose.arn` |