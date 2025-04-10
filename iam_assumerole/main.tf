# -- Variables --

variable "enabled" {
  description = "Whether or not to create the role/policy/attachment resources."
  type        = bool
  default     = true
}

variable "custom_iam_policies" {
  description = "The names of any additional IAM policies to attach to the role."
  type        = list(string)
  default     = []
}

variable "master_assumerole_policy" {
  description = "Policy document to attach to the role allowing AssumeRole access from a master account."
}

variable "iam_policies" {
  description = "Name/description/document properties for policy/policies."
  type        = list(list(string))
}

variable "role_duration" {
  description = "Value for the max_session_duration for the role, in seconds."
  type        = number
  default     = 43200
}

variable "role_name" {
  description = "Name of the IAM role."
}

variable "role_description" {
  description = "A description/summary of the IAM role being created."
  default     = ""
}

variable "permissions_boundary_policy_arn" {
  description = <<EOM
(REQUIRED) ARN of an existing IAM policy (from another module/source)
which will be used as the Permissions Boundary for the IAM role.
EOM
  type        = string
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

# -- Data Sources --

# create policy document
data "aws_iam_policy_document" "iam_policy_doc" {
  count                   = var.enabled ? length(var.iam_policies) : 0
  source_policy_documents = var.iam_policies[count.index]
}

# obtain data/ARNs for every entry in var.custom_iam_policies
data "aws_iam_policy" "custom" {
  for_each = var.enabled ? toset(var.custom_iam_policies) : []
  name     = each.key
}

# -- Resources --

resource "aws_iam_policy" "iam_role_policy" {
  count = var.enabled ? 1 * length(var.iam_policies) : 0

  name        = "${var.role_name}${count.index + 1}"
  description = "Policy ${count.index + 1} for ${var.role_name} role"
  policy      = data.aws_iam_policy_document.iam_policy_doc[count.index].json

  lifecycle {
    precondition {
      # This precondition check validates IAM policies meet maximum length requirements and fails fast (in terraform plan operations)
      # aws_iam_policy_document.json returns non-minified json structures but aws_iam_policy consumes the input as a minified json structure.
      # The jsondecode and jsonencode operations result in the minified json strucutre.
      condition     = length(jsonencode(jsondecode(data.aws_iam_policy_document.iam_policy_doc[count.index].json))) <= 6144
      error_message = "The IAM policy ${var.role_name}${count.index + 1} exceeds the maximum allowed length (6144 characters.) Current Length: ${length(jsonencode(jsondecode(data.aws_iam_policy_document.iam_policy_doc[count.index].json)))}"
    }
  }
}

resource "aws_iam_role" "iam_assumable_role" {
  count = var.enabled ? 1 : 0

  name                 = var.role_name
  description          = var.role_description
  assume_role_policy   = var.master_assumerole_policy
  path                 = "/"
  max_session_duration = var.role_duration #seconds
  permissions_boundary = var.permissions_boundary_policy_arn
}

resource "aws_iam_role_policy_attachment" "policy_attachment_main" {
  count = var.enabled ? 1 * length(var.iam_policies) : 0

  role       = aws_iam_role.iam_assumable_role[0].name
  policy_arn = aws_iam_policy.iam_role_policy[count.index].arn
}

resource "aws_iam_role_policy_attachment" "policy_attachment_custom" {
  for_each = var.enabled ? data.aws_iam_policy.custom : {}

  role       = aws_iam_role.iam_assumable_role[0].name
  policy_arn = each.value.arn
}

# -- Outputs --

output "iam_assumable_role" {
  value = var.enabled ? aws_iam_role.iam_assumable_role[0] : null
}
