variable "ec2_kms_arns" {
  default     = []
  description = "ARN(s) of EC2 roles permitted access to KMS"
}

variable "env_name" {
  description = "Environment name"
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue used as the CloudWatch event target."
}

variable "primary_key_arn" {
  description = "ARN of the multi-region kms key."
}
