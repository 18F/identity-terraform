# `kms_keymaker`

This Terraform module will generate a replicated KMS key + alias for use by the Login.gov IdP application, along with a CloudWatch event monitor, and its target (an SNS topic/subscription). It is best utilized alongside the `kms_log` module, which creates the SQS queue (whose ARN is a required variable in this module) that SNS sends messages to.

These resources were, previously, all included within `kms_log` in a more monolithic design; they have been split out separately to allow for multi-region KMS keys and associated resources.

## Example

```hcl
  module "kms_keymaker_replica_ue1" {
  source = "github.com/18F/identity-terraform//kms_keymaker_replica?ref=main"

  providers = {
    aws = aws.use1
  }
  
  env_name        = "testing"
  ec2_kms_arns    = local.kms_arns
  sqs_queue_arn   = module.kms_logging.kms-ct-events-queue
  primary_key_arn = module.kms_keymaker_uw2.multi_region_primary_key_arn
}

## Variables

`ec2_kms_arns` - ARN(s) of EC2 roles permitted access to KMS
`env_name` - Environment name
`sqs_queue_arn` - ARN of the SQS queue used as the CloudWatch event target
`primary_key_arn` - ARN of the multi-region key to replicate
