# -- Variables --

variable "enabled" {
  description = "Whether or not to create the role/policy/attachment resources."
  type = bool
  default = true
}

variable "custom_policy_arns" {
  description = "The ARNs of any additional IAM policies to attach to the role."
  type = []
}

variable "policy_description" {
  description = "Description of policy including access provided."
}

variable "policy_name" {
  description = "Name of the IAM policy for the role."
}

variable "role_duration" {
  description = "Value for the max_session_duration for the role, in seconds."
  type = number
  default = 43200
}

variable "role_name" {
  description = "Name of the IAM role."
}

variable "statement" {
  description = "Statement to add to the IAM policy document."
  type = {}
}

# -- Resources --

# create policy document; iterate through statements{} via dynamic
data "aws_iam_policy_document" "iam_policy_doc" {
  count = var.enabled ? 1 : 0

  dynamic "statement" {
    for_each = var.statement
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role" "iam_assumable_role" {
  count = var.enabled ? 1 : 0

  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.master_account_assumerole.json
  path                 = "/"
  max_session_duration = var.role_duration #seconds
}

resource "aws_iam_policy" "iam_role_policy" {
  count = var.enabled ? 1 : 0

  name        = var.policy_name
  description = var.policy_description
  policy      = data.aws_iam_policy_document.iam_policy_doc[0].json
}

resource "aws_iam_role_policy_attachment" "policy_attachment_main" {
  count = var.enabled ? 1 : 0

  role       = aws_iam_role.iam_assumable_role[0].name
  policy_arn = aws_iam_policy.iam_role_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "policy_attachment_custom" {
  count = var.enabled ? 1 * length(var.custom_policy_arns) : 0

  role       = aws_iam_role.iam_assumable_role[0].name
  policy_arn = element(var.custom_policy_arns, count.index)
}

# -- Outputs --

output "iam_role_arn" {
  description = "ARN of the created IAM role."
  value = aws_iam_role.iam_assumable_role[0].arn
}

output "iam_policy_arn" {
  description = "ARN of the created IAM policy."
  value = aws_iam_policy.iam_role_policy[0].arn
}
