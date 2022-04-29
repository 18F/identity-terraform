locals {
  zip_file        = var.zip_filename == "" ? var.function_name : var.zip_filename
  statement_id    = var.perm_id == "" ? "${var.function_name}-lambda-permission" : var.perm_id
  environment_map = var.env_var_map[*]
}

variable "source_code_filename" {
  description = "(REQUIRED) Name (with extension) of file containing function source code."
  type        = string
  default     = "lambda_function.py"
}

variable "source_dir" {
  description = <<EOM
(REQUIRED) Name of directory where source_code_filename + any other
files to be added to the ZIP file reside.
EOM
  type        = string
  default     = "src"
}

variable "zip_filename" {
  description = <<EOM
(OPTIONAL) Custom name for the ZIP file containing Lambda source code.
Will default to function_name if not specified here.
EOM
  type        = string
  default     = ""
}

variable "external_role_arn" {
  description = <<EOM
(OPTIONAL) ARN of an external IAM role used by the Lambda function, one with
(at least) the sts:AssumeRole permission. If not specified, a role named
function_name-lambda-role with said basic permission will be created and used instead.
EOM
  type        = string
  default     = ""
}

variable "function_name" {
  description = "(REQUIRED) Name of the Lambda function."
  type        = string
}

variable "description" {
  description = "(REQUIRED) Description of the Lambda function."
  type        = string
}

variable "handler" {
  description = "(REQUIRED) Handler for the Lambda function."
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "memory_size" {
  description = "(REQUIRED) Memory (in MB) available to the Lambda function."
  type        = number
  default     = 3008
}

variable "runtime" {
  description = "(REQUIRED) Runtime used by the Lambda function."
  type        = string
  default     = "python3.8"
}

variable "timeout" {
  description = "(REQUIRED) Timeout value for the Lambda function."
  type        = number
  default     = 300
}

variable "env_var_map" {
  description = "(OPTIONAL) Map of environment variables used by the Lambda function, if any."
  type        = map(string)
  default     = null
}

variable "perm_id" {
  description = <<EOM
(OPTIONAL) ID/name of Statement identifying the permission for the function.
Will default to function_name-lambda-permission if not specified here.
EOM
  type        = string
  default     = ""
}

variable "permission_principal" {
  description = <<EOM
(OPTIONAL) Service principal for Lambda permission, e.g. events.amazonaws.com.
ONLY use if desiring to create an AWS Lambda Permission. Must be in list format.
EOM
  type        = list(string)
  default     = []
}

variable "permission_source_arn" {
  description = <<EOM
(OPTINAL) ARN of resource referenced by/connected to principal for Lambda permission.
ONLY use if desiring to create an AWS Lambda Permission.
EOM
  type        = string
  default     = ""
}
