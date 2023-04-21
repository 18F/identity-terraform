variable "ec2_kms_arns" {
  default     = []
  description = "ARN(s) of EC2 roles permitted access to KMS"
}

variable "env_name" {
  type        = string
  description = "Environment name"
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the SQS queue used as the CloudWatch event target."
}