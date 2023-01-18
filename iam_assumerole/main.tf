# -- Variables --

variable "enabled" {
  description = "Whether or not to create the role/policy/attachment resources."
  type        = bool
  default     = true
}

variable "custom_policy_arns" {
  description = "The ARNs of any additional IAM policies to attach to the role."
  type        = list(any)
  default     = []
}

variable "master_assumerole_policy" {
  description = "Policy document to attach to the role allowing AssumeRole access from a master account."
}

variable "iam_policies" {
  description = "Name/description/document properties for policy/policies."
  type = list(object({
    policy_name        = string
    policy_description = string
    policy_document = list(object({
      sid       = string
      effect    = string
      actions   = list(string)
      resources = list(string)
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })))
    }))
  }))
}

variable "role_duration" {
  description = "Value for the max_session_duration for the role, in seconds."
  type        = number
  default     = 43200
}

variable "role_name" {
  description = "Name of the IAM role."
}

variable "permissions_boundary_policy_arn" {
  description = <<EOM
(REQUIRED) ARN of an existing IAM policy (from another module/source)
which will be used as the Permissions Boundary for the IAM role.
EOM
}

# -- Resources --

# create policy document; iterate through statements{} via dynamic
data "aws_iam_policy_document" "iam_policy_doc" {
  count = var.enabled ? 1 * length(var.iam_policies) : 0

  dynamic "statement" {
    for_each = var.iam_policies[count.index].policy_document
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources

      dynamic "condition" {
        for_each = (
          statement.value["conditions"] == null ? [] : statement.value["conditions"]
        )
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_policy" "iam_role_policy" {
  count = var.enabled ? 1 * length(var.iam_policies) : 0

  name        = var.iam_policies[count.index].policy_name
  description = var.iam_policies[count.index].policy_description
  policy      = data.aws_iam_policy_document.iam_policy_doc[count.index].json
}

resource "aws_iam_role" "iam_assumable_role" {
  count = var.enabled ? 1 : 0

  name                 = var.role_name
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
  count = var.enabled ? 1 * length(var.custom_policy_arns) : 0

  role       = aws_iam_role.iam_assumable_role[0].name
  policy_arn = element(var.custom_policy_arns, count.index)
}

output "iam_assumable_role" {
  value = aws_iam_role.iam_assumable_role
}
