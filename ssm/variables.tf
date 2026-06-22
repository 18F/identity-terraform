variable "ssm_session_doc_map" {
  type = map(object({
    description = string
    command     = string
    logging     = bool
  }))
  description = <<EOM
Map of data for SSM Standard_Stream Session Documents. Each must map the document name to a description, the command
to run when connected (i.e. a shell to invoke), and whether to log the output from the session to S3 + CloudWatch.
EOM
  default = {
    #"login" = {
    #  description = "Login shell"
    #  command     = "cd ; /bin/bash"
    #  logging     = false
    #  exit        = true
    #},
  }
}

variable "ssm_cmd_doc_map" {
  type = map(object({
    description = string
    parameters = list(object({
      name        = string
      type        = string
      description = string
      pattern     = optional(string)
      values      = optional(list(string))
      default     = string
    }))
    command = list(string)
    logging = bool
    timeout = optional(number, 3600)
  }))
  description = <<EOM
Map of data for SSM Command Documents. Each must map the document name to a description, the list of command(s)
to run, any parameter(s) used to configure said command(s), and whether to create a CloudWatch Log Group for
logging output(s) of said command(s) if `--cloud-watch-output-config` is passed into the `ssm send-command` operation.
Any commands which do not specify an 'executionTimeout' parameter -- the timeout, in seconds, that said command(s)
are allowed to run before being assumed to have failed, and thus halted by SSM -- will automatically get said
parameter added during SSM document creation; it defaults to 3600 seconds, but can be adjusted per-command by
specifying a timeout value (as shown in the 'type' above).
EOM
  default = {
    #"uptime" = {
    #  description = "Verify host uptime"
    #  parameters = [
    #    {
    #      name        = "uptimeCommand"
    #      type        = "String"
    #      description = "Command to run"
    #      default     = "uptime"
    #    },
    #  ]
    #  command = [
    #    "echo $( {{ uptimeCommand }} )",
    #  ]
    #  timeout = 60
    #  logging = true
    #},
  }
}

variable "ssm_interactive_cmd_map" {
  type = map(object({
    description = string
    parameters = optional(list(object({
      name        = string
      type        = string
      description = string
      pattern     = optional(string)
      values      = optional(list(string))
      default     = string
    })))
    command      = list(string)
    run_elevated = bool
    logging      = bool
  }))
  description = <<EOM
Map of data for SSM InteractiveCommand Session Documents. Each must map the document name to a description,
command(s) to run, any parameter(s) used to configure said command(s), whether or not to run the command(s) as root,
and whether to log the output from the session to S3 + CloudWatch.
EOM
  default = {
    #"tail-syslog" = {
    #  description = "Tail /var/log/syslog on a host"
    #  parameters = [
    #    {
    #      name        = "logpath"
    #      type        = "String"
    #      description = "log file to tail/read"
    #      pattern     = "^[a-zA-Z0-9-_/]+(.log)$"
    #      default     = "/var/log/syslog"
    #    }
    #  ]
    #  command = [
    #    "tail -f {{ logpath }}"
    #  ]
    #  run_elevated = true
    #  logging      = true
    #},
  }
}

variable "ssm_portforward_cmd_map" {
  type = map(object({
    description = string
    parameters = list(object({
      name        = string
      type        = string
      description = string
      pattern     = optional(string)
      values      = optional(list(string))
      default     = string
    }))
    logging = bool
  }))
  description = <<EOM
Map of data for SSM Port Forwarding Documents. Each must map the document name to a description, parameters for the
session (portNumber, localPortNumber, and host), and whether to log the output from the session to S3 + CloudWatch.
EOM
  default     = {}
}

variable "session_timeout" {
  type        = number
  description = "Amount of time (in minutes) of inactivity to allow before a session ends."
  default     = 15
}

variable "region" {
  type        = string
  description = "AWS Region for the module."
  default     = "us-west-2"
}

variable "env_name" {
  type        = string
  description = "Environment name"
}

variable "bucket_name_prefix" {
  type        = string
  description = "First substring in S3 bucket name of $bucket_name_prefix.$env_name-ssm-logs.$account_id-$region"
}

variable "inventory_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket used for collecting S3 Inventory reports."
}

variable "logging_bucket_id" {
  type        = string
  description = "ID (name) of the S3 bucket used for logging S3 access events."
}

variable "force_destroy_ssm_logs_bucket" {
  type        = bool
  description = "Allow destruction of the ssm_logs S3 bucket, even if it contains objects."
  default     = false
}

variable "s3_bucket_key_enabled" {
  type        = bool
  description = "Whether or not to use a Bucket Key for the S3 bucket(s) in this module."
  default     = false
}

variable "s3_blocked_encryption_types" {
  type        = list(string)
  description = "Single-item list of SSE types to block for object uploads to the S3 bucket(s) in this module."
  default = [
    "SSE-C"
  ]

  validation {
    condition     = contains(["NONE", "SSE-C"], var.s3_blocked_encryption_types[0])
    error_message = "var.s3_blocked_encryption_types must be set to 'NONE' or 'SSE-C'."
  }
}

variable "cloudwatch_retention_days" {
  description = "Number of days to retain Streams for all CloudWatch Log Groups defined in/created by this module."
  type        = number
  default     = 365
}

variable "prevent_tf_log_deletion" {
  type        = bool
  description = <<EOM
Whether to ACTUALLY destroy CloudWatch Log Groups in this module vs. just removing them from state when using -destroy.
EOM
  default     = false
}
