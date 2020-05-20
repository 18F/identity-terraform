# -- Variables --

variable "account_numbers" {
  description = "List of AWS account numbers where this policy can access the specified Assumable role"
  type = list(any)
}

variable "role_type" {
  description = "Type/name of the Assumable role. Should correspond to an actual role name in the account(s) listed."
}

variable "account_type" {
  description = "Type/name that the listed account(s) fall under (e.g. prod, dev, etc.)"
}

# -- Resources --

resource "aws_iam_policy" "role_type_policy" {
  name        = join("", [title(var.account_type), "Assume", title(var.role_type)]))
  path        = "/"
  description = "Policy to allow user to assume ${var.role_type} role in ${var.account_type}."
  policy      = data.aws_iam_policy_document.role_type_policy.json
}

data "aws_iam_policy_document" "role_type_policy" {
  statement {
    sid    = join("", [title(var.account_type), "Assume", title(var.role_type)]))
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = formatlist("arn:aws:iam::%s:role/${var.role_type}",var.account_numbers)
  }
}
