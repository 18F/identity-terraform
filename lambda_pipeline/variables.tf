variable build_account {
  description = "Build Acccount Id"
  type = string
}

variable shared_accounts {
  description = "List of accounts to share artifacts with"
  type = list
  default = []
}
variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "cf_stack_name" {
  description = "Stack name for SAM/Cloudformation."
  type        = string
}

variable "project_name" {
  description = "Codebuild project name"
  type        = string
}

variable "project_description" {
  description = "Codebuild project description"
  type        = string
}

# bucket that the SAM/Cloudformation template reside
variable "project_template_s3_bucket" {
  description = "Project template S3 bucket"
  type        = string
}

# key to the SAM/Cloudformation template
variable "project_template_object_key" {
  description = "Project template object key"
  type        = string
}

# bucket that the layers and function reside
variable "project_artifacts_s3_bucket" {
  description = "Project artifacts S3 bucket"
  type        = string
}

variable "parameter_application_functions" {
  description = "SSM Parameter for application functions list (if needed)"
  type        = string
  default     = "none"
}

variable "vpc_arn" {
  description = "VPC arn for functions that require vpc access"
  type        = string
}

variable "pipeline_failure_notification_arn" {
  description = "SNS topic arn for pipeline failure notification"
  type        = string
}