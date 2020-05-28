variable "group_name" {
  description = "Name of the IAM group."
}

variable "master_account_id" {
  description = "AWS account ID for the master account."
}

variable "group_members" {
  description = "AWS usernames of members within the group."
  type        = list(any)
  default     = []
}

variable "iam_group_roles" {
  description = "Roles map for IAM group, along with account types per role to grant access to."
  type = list(object({
    role_name  = string
    account_types = list(any)
  }))
}

locals {
  account_roles = flatten(
    [
      for role in var.iam_group_roles : [
        for pair in setproduct([role.role_name],role.account_types) :
          join("Assume",[pair[1],pair[0]]
        )
      ]
    ]
  )
}
# -- Resources --

resource "aws_iam_group" "iam_group" {
  name = var.group_name
}

resource "aws_iam_group_membership" "iam_group_members" {
  name = "${var.group_name}_members"
  users = var.group_members
  group = var.group_name
}

resource "aws_iam_group_policy_attachment" "iam_group_policies" {
  for_each = {
    for role_name in local.account_roles: lower(role_name) => role_name
  }
  
  group = var.group_name
  policy_arn = "arn:aws:iam::${var.master_account_id}:policy/${each.value}"
}