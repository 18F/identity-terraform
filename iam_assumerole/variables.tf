variable "custom_iam_policies" {
  type        = list(string)
  description = "The names of any additional IAM policies to attach to the role."
  default     = []
}

variable "master_assumerole_policy" {
  type        = string
  description = "Policy document to attach to the role allowing AssumeRole access from a 'master' account."
}

variable "iam_policies" {
  type        = list(list(string))
  description = <<EOM
Lists of JSON content (.json attribute) of one or more aws_iam_policy_document data sources. Each list of data sources
is converted to an aws_iam_policy resource, attached as a managed policy to the assumable IAM role; as such, the total
length of all minified-JSON versions of all documents must not exceed 6,144 characters (per policy, i.e. per list).
EOM
}

variable "role_duration" {
  type        = number
  description = "Value for the max_session_duration for the role, in seconds. Defaults to 43200 (12h)."
  default     = 43200
}

variable "role_name" {
  type        = string
  description = "Name of the IAM role."
}

variable "role_tags" {
  type        = map(string)
  description = "Tags to apply to the IAM role, if using any."
  default = {
    # RedshiftDbGroups  = "lg_users"
  }
}

variable "role_description" {
  type        = string
  description = "A description/summary of the IAM role being created."
  default     = ""
}

variable "permissions_boundary_policy_arn" {
  type        = string
  description = "ARN of an externally-created IAM policy used as the Permissions Boundary for the IAM role."
  default     = ""

  ### OPTIONAL: To enforce that a Permissions Boundary policy must exist, and must
  ### be attached to role(s) using this module, comment out the 'default' line/value
  ### above, and uncomment the 'validation' block below. This will REQUIRE a valid
  ### ARN from an existing Permissions Boundary policy created outside of the module.
  #  validation {
  #    condition = can(regex(
  #      "^arn:aws:iam::[\\d]{12}:policy\\/[\\w+=,.@-]+$",
  #      var.permissions_boundary_policy_arn
  #    ))
  #    error_message = <<EOM
  #The permissions_boundary_policy_arn variable must be a valid AWS ARN,
  #e.g.: arn:aws:iam::123456789012:policy/XCompanyBoundaries
  #EOM
  #  }
}

