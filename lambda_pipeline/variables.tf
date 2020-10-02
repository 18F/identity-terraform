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

variable "project_source_s3_bucket" {
  description = "Project source S3 bucket"
  type        = string
}

variable "project_source_object_key" {
  description = "Project source object key"
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