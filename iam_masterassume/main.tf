# -- Variables --
variable "partition" {
  description = "which aws partition this is deployed in"
  type        = string
  default     = "aws"
}

variable "aws_account_types" {
  description = "Mapping of account types to lists of AWS account numbers."
  type        = map(list(string))
}

variable "role_list" {
  description = "Type/name of the Assumable role(s). Should correspond to actual role name(s) in the account(s) listed."
  type        = list(any)
}

variable "username_tag" {
  type        = string
  default     = "ec2_username"
  description = <<EOM
Name of an AWS tag used to assign a username (for SSM access via SSMSessionRunAs tags)
to an AWS user. Defaults to 'ec2_username' as per the iam_masterusers module.
EOM
}

locals {
  # Build an enumerated map of "ACCOUNT_TYPEAssumeROLE" elements
  # to build policy documents and policies from.
  role_expansion = {
    for rolepair in setproduct(keys(var.aws_account_types), var.role_list) : join("", [rolepair[0], "Assume", rolepair[1]]) => [
      for pair in setproduct(var.aws_account_types[rolepair[0]], [rolepair[1]]) :
      join("", ["arn:${var.partition}:iam::", pair[0], ":role/", pair[1]])
    ]
  }
}

# -- Resources --

data "aws_iam_policy_document" "role_policy_doc" {
  for_each = local.role_expansion

  statement {
    sid    = each.key
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      for arn in each.value : arn
    ]
    condition {
      test     = "StringEquals"
      variable = "sts:RoleSessionName"

      values = [
        "$${aws:username}",
      ]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"

      values = [
        "true",
      ]
    }
  }

  statement {
    sid    = "${each.key}TagSessions"
    effect = "Allow"
    actions = [
      "sts:TagSession"
    ]
    resources = [
      for arn in each.value : arn
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"

      values = [
        "true",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/SSMSessionRunAs"

      values = [
        "&{aws:PrincipalTag/${var.username_tag}}",
      ]
    }
  }
}

resource "aws_iam_policy" "account_role_policy" {
  for_each = local.role_expansion

  name        = each.key
  path        = "/"
  description = "Policy to allow user to assume ${split("Assume", each.key)[1]} role in ${split("Assume", each.key)[0]} account(s)."
  policy      = data.aws_iam_policy_document.role_policy_doc[each.key].json
}

# -- Outputs --

output "policy_arns" {
  description = "Reference this output in order to depend on policy creation being complete."
  value       = values(aws_iam_policy.account_role_policy)[*]["arn"]
}
