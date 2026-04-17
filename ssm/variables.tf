variable "ssm_doc_map" {
  description = <<EOM
REQUIRED. Map of data for SSM Session Documents. Each must include the document name,
description, command(s) to run at login, and whether to log the commands/output
from the given session/document.
EOM
  type        = map(map(string))
  default = {
    "default" = {
      description = "Login shell"
      command     = "cd ; /bin/bash"
      logging     = false
      exit        = true
    },
  }
}

variable "ssm_cmd_doc_map" {
  description = <<EOM
REQUIRED. Map of data for SSM Command Documents. Each must include the document name,
description, command to run, any parameter(s) used to configure said command, and
whether to log the commands/output from the given session/document.
EOM
  type        = map(any)
  default = {
    "uptime" = {
      description = "Verify host uptime"
      command     = ["uptime"]
      logging     = false
      parameters  = []
    },
  }
}

variable "ssm_interactive_cmd_map" {
  description = <<EOM
REQUIRED. Map of data for SSM InteractiveCommand Session Documents. Each must
include the document name, description, command to run, and any parameter(s) used
to configure said command.
EOM
  type        = map(any)
  default = {
    "ifconfig" = {
      description = "Check network interface configuration"
      command     = ["ifconfig"]
      parameters  = []
    },
  }
}

variable "ssm_portforward_cmd_map" {
  description = <<EOM
REQUIRED. Map of data for SSM Port Forwarding Documents. Each must
include the document name, description, command to run, and any parameter(s) used
to configure said command.
EOM
  type        = map(any)
  default     = {}
}


variable "session_timeout" {
  description = <<EOM
REQUIRED. Amount of time (in minutes) of inactivity
to allow before a session ends.
EOM
  type        = number
  default     = 15
}

variable "region" {
  description = "REQUIRED. AWS Region"
  type        = string
}

variable "env_name" {
  description = "REQUIRED. Environment name"
  type        = string
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

variable "force_destroy" {
  description = "(OPTIONAL) Allow destruction of the ssm_logs S3 bucket, even if it contains objects."
  type        = bool
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
    "NONE"
  ]

  validation {
    condition     = contains(["NONE", "SSE-C"], var.s3_blocked_encryption_types[0])
    error_message = "var.s3_blocked_encryption_types must be set to 'NONE' or 'SSE-C'."
  }
}

locals {
  all_docs_and_cmds = toset(compact(flatten([
    keys(var.ssm_doc_map),
    keys(var.ssm_interactive_cmd_map),
    keys(var.ssm_cmd_doc_map)
  ])))
}
