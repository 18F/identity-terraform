# -- Variables --

variable "assume_role_policy_arns" {
  description = "The ARNs of IAM policies to attach to the group."
  type        = list(any)
  default     = []
}

variable "group_members" {
  description = "AWS usernames of members within the group."
  type        = list(any)
  default     = []
}

variable "group_name" {
  description = "Name of the IAM group."
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
  for_each = var.assume_role_policy_arns

  group = var.group_name
  policy_arn = each.key
}