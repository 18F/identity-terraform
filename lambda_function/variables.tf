variable "region" {
  type        = string
  description = "AWS Region for the module."
  default     = "us-west-2"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string

  validation {
    condition     = length(var.function_name) > 0 && length(var.function_name) <= 64
    error_message = "function_name must be a non-empty string with max length 64."
  }
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string

  validation {
    condition     = length(var.description) > 0 && length(var.description) <= 256
    error_message = "description must be a non-empty string with max length 256 characters."
  }
}

variable "handler" {
  description = "Full Lambda handler string"
  type        = string
  default     = ""
}

variable "handler_function_name" {
  description = "Lambda handler function name"
  type        = string
  default     = "lambda_handler"
}

variable "source_code_filename" {
  description = "Name of the file containing the Lambda source code"
  type        = string

  validation {
    condition     = length(var.source_code_filename) > 0
    error_message = "source_code_filename must be a non-empty string."
  }
}

variable "source_dir" {
  type        = string
  description = <<EOM
Directory containing the Lambda source code, i.e. '$path.module/src/'. Ideally, should specifically point to
the directory where the main function code file exists. Said directory should NOT contain any files/directories/etc.
for Lambda layers, if any exist/should be created for the function. CANNOT be left blank.
EOM

  validation {
    condition     = length(var.source_dir) > 0
    error_message = "source_dir must be a non-empty string."
  }
}

variable "output_dir" {
  type        = string
  description = <<EOM
Directory where the archive_file data source should output a ZIP file containing code for the Lambda function.
If Lambda Layers are being utilized (i.e. via resources in var.layer_dir), an archive_file for the dependencies
will also be used to output a ZIP to this path. CANNOT be the same as either var.source_dir or var.layer_dir.
EOM

  validation {
    condition     = length(var.source_dir) > 0
    error_message = "source_dir must be a non-empty string."
  }

  validation {
    condition = alltrue([
      var.output_dir != var.source_dir,
      var.output_dir != var.layer_dir
    ])
    error_message = "output_dir cannot be the same as either layer_dir or source_dir."
  }
}


variable "memory_size" {
  description = "Memory allocated to the Lambda function"
  type        = string
  default     = "128"

  validation {
    condition = (
      can(tonumber(var.memory_size)) &&
      tonumber(var.memory_size) >= 128 &&
      tonumber(var.memory_size) <= 10240 &&
      tonumber(var.memory_size) % 1 == 0
    )
    error_message = "Memory size must be a whole number between 128 and 10240 MB (e.g., '512')."
  }
}

variable "runtime" {
  description = "Lambda function runtime"
  type        = string

  validation {
    condition     = length(trimspace(var.runtime)) > 0
    error_message = "runtime must be a non-empty string."
  }
}

variable "timeout" {
  description = "Lambda timeout"
  type        = number
  default     = 120

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

variable "environment_variables" {
  description = <<EOM
  Environment variables for the Lambda function. Individual variables must be
  of a type that terraform can convert to strings. Lists and maps must be
  `jsonencode`ed.
  EOM
  type        = map(any)

  validation {
    condition     = alltrue([for k, v in var.environment_variables : length(k) > 0 && can(tostring(v))])
    error_message = "Each environment variable must have a non-empty key and a value convertible to string."
  }
}

variable "reserved_concurrent_executions" {
  type        = number
  description = "The max number concurrent invocations allowed for the Lambda"
  default     = -1
}

variable "role_name_prefix" {
  type        = string
  description = <<EOM
Prefix string used to specify the name of the function's IAM role. Required if creating the same function in
multiple regions. If not specified, will set the role name to the value of var.lambda_iam_role_name
or the default of '{var.function_name}-lambda-role'.
EOM
  default     = null
}

variable "log_skip_destroy" {
  description = "Skip log destruction"
  type        = bool
  default     = false
}

variable "cloudwatch_retention_days" {
  default = 2192
  type    = number

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_retention_days)
    error_message = "cloudwatch_retention_days must be one of the following values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653."
  }
}

variable "lambda_iam_policy_document" {
  default     = ""
  type        = string
  description = "IAM permissions for the lambda function. Use a data.aws_iam_policy_document to construct"
}

variable "lambda_iam_role_name" {
  default     = null
  type        = string
  description = <<EOM
Role name override for resources that need underscores.
If not specified, will set the role name to the default of '{var.function_name}-lambda-role'
If var.role_name_prefix is set, the module will use the name prefix instead of the role name
EOM
}

variable "iam_role_description" {
  default     = ""
  description = "Description of the iam role associated with the lambda function"
  type        = string
}

variable "schedule_expression" {
  default     = ""
  description = "Cron or rate expression to trigger lambda"
  type        = string

  validation {
    condition = (
      var.schedule_expression == "" ||
      can(regex("^rate\\(.*\\)$|^cron\\(.*\\)$", var.schedule_expression))
    )
    error_message = "The schedule_expression must be a valid 'rate()' or 'cron()' expression."
  }
}

variable "event_pattern" {
  default     = ""
  description = "EventBridge pattern to trigger lambda"
  type        = string
}

# Lambda Layers

variable "insights_layer_enabled" {
  type        = bool
  description = <<EOM
If set to 'true', will add the LambdaInsightsExtension from the Lambda Insights AWS account as a Layer for the function.
If adding a custom layer via var.layer_name, it will be added /after/ the insights layer.
EOM
  default     = true
}

variable "layer_name" {
  type        = string
  description = "Identifier used to name the Lambda Layer, if using one."
  default     = ""
}

variable "layer_dir" {
  type        = string
  description = <<EOM
Directory containing any dependencies for the Lambda function to add as a Layer for said function, if using any.
Ideally, said directory is in the same parent as var.source_dir for better organization within the filesystem.
Should NOT contain any files/directories/etc. for the core function code, nor should it be the same as the source dir.
EOM
  default     = ""

  validation {
    condition     = var.layer_dir != var.source_dir
    error_message = "layer_dir and source_dir must not be the same."
  }
}

variable "layer_s3_bucket" {
  type        = string
  description = <<EOM
Full name of an S3 bucket which is used to store the ZIP files for Lambda Layers, which are managed via the
lambda_layer s3 object resource. Leave blank if not using Lambda Layers.
EOM
  default     = ""
}

# lambda_alerts module

variable "lambda_alerts_enabled" {
  type        = bool
  description = <<EOM
Whether or not to create the lambda_alerts module, which consists of CloudWatch Metric Alarms
that track error rate, memory usage, and function execution duration.
EOM
  default     = true
}

variable "env_name" {
  type        = string
  description = "Name of the environment in which the lambda function lives"
  default     = ""
}

variable "alarm_actions" {
  description = "ARNs for Cloudwatch Alarm actions"
  type        = list(any)

  validation {
    condition     = alltrue([for action in var.alarm_actions : length(trimspace(action)) > 0])
    error_message = "Each alarm action must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for action in var.alarm_actions :
      can(regex("^arn:aws:sns:[a-z0-9-]+:\\d{12}:[a-zA-Z0-9-_]+$", action))
    ])
    error_message = "Each alarm action must be a valid SNS topic ARN."
  }
}

variable "ok_actions" {
  description = "ARNs for Cloudwatch OK actions"
  type        = list(any)
  default     = []
}

variable "runbook" {
  type        = string
  description = "A link to a runbook associated with any metric in this module"
  default     = ""

  validation {
    condition = (
      var.runbook == "" || can(regex("^https?://[\\w.-]+(?:\\.[\\w.-]+)+(?:[/\\w._-]*)?$", var.runbook))
    )
    error_message = "Runbook must be a valid HTTP or HTTPS URL (e.g., ‘https://example.com/runbook’)."
  }
}

variable "error_rate_operator" {
  type        = string
  description = "The operator used to compare a calculated error rate against a threshold"
  default     = "GreaterThanOrEqualToThreshold"

  validation {
    condition = contains([
      "GreaterThanOrEqualToThreshold",
      "GreaterThanThreshold",
      "LessThanThreshold",
      "LessThanOrEqualToThreshold"
    ], var.error_rate_operator)

    error_message = "error_rate_operator must be one of: GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold or LessThanOrEqualToThreshold."
  }
}

variable "error_rate_threshold" {
  type        = number
  description = "The threshold error rate (as a percentage) for triggering an alert"
  default     = 1
}

variable "memory_usage_threshold" {
  type        = number
  description = "The threshold memory utilization (as a percentage) for triggering an alert"
  default     = 90
}

variable "duration_threshold" {
  type        = number
  description = "The duration threshold (as a percentage) for triggering an alert"
  default     = 80

  validation {
    condition     = var.duration_threshold >= 0 && var.duration_threshold <= 100
    error_message = "Duration threshold must be a percentage between 0 and 100."
  }
}

variable "datapoints_to_alarm" {
  type        = number
  description = "The number of datapoints that must be breaching to trigger the alarm."
  default     = 1
}

variable "evaluation_periods" {
  type    = number
  default = 1
}

variable "period" {
  type        = number
  description = "The period in seconds over which the specified statistic is applied."
  default     = 60
}

variable "treat_missing_data" {
  default = "notBreaching"
  type    = string

  validation {
    condition = contains([
      "breaching",
      "notBreaching",
      "ignore",
      "missing"
    ], var.treat_missing_data)

    error_message = "treat_missing_data must be one of: breaching, notBreaching, ignore, or missing."
  }
}

variable "error_rate_alarm_name_override" {
  type        = string
  description = "Overrides the default alarm naming convention with a custom name"
  default     = ""
}
variable "memory_usage_alarm_name_override" {
  type        = string
  description = "Overrides the default alarm naming convention with a custom name"
  default     = ""
}
variable "duration_alarm_name_override" {
  type        = string
  description = "Overrides the default alarm naming convention with a custom name"
  default     = ""
}

variable "error_rate_alarm_description" {
  type        = string
  description = "Overrides the default alarm description for error rate alarm"
  default     = ""
}

variable "memory_usage_alarm_description" {
  type        = string
  description = "Overrides the default alarm description for memory usage alarm"
  default     = ""
}

variable "duration_alarm_description" {
  type        = string
  description = "Overrides the default alarm description for duration alarm"
  default     = ""
}
