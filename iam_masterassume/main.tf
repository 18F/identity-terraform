# -- Variables --

variable "account_type" {
  description = "Type of account."
}

variable "account_numbers" {
  description = "List of AWS account numbers where this policy can access the specified Assumable role"
  type = list(any)
}

variable "role_list" {
  description = "Type/name of the Assumable role(s). Should correspond to actual role name(s) in the account(s) listed."
  type = list(any)
}

locals {
  role_arn_map = { for role in var.role_list : role => [
    for pair in setproduct(var.account_numbers, [role]) :
      join("",["arn:aws:iam::",pair[0],":role/",pair[1]])
    ]
  }
}

# -- Resources --

data "aws_iam_policy_document" "role_policy_doc" {
  for_each = local.role_arn_map

  statement {
      sid       = join("", [var.account_type, "Assume", each.key])
      effect    = "Allow"
      actions   = [
        "sts:AssumeRole"
      ]
      resources = [
        for arn in each.value : "${arn}"
      ]
  }
}

resource "aws_iam_policy" "account_role_policy" {
  count = length(var.role_list)

  name        = join("", [var.account_type, "Assume", var.role_list[count.index]])
  path        = "/"
  description = "Policy to allow user to assume ${var.role_list[count.index]} role in ${var.account_type} account(s)."
  policy = data.aws_iam_policy_document.role_policy_doc[var.role_list[count.index]].json
}
