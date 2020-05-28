variable "user_map" {
  description = "Map of users to group memberships."
  type        = map(list(string))
}


# -- Resources --

resource "aws_iam_user" "master_user" {
  for_each = var.user_map

  name          = each.key
  force_destroy = true
}

resource "aws_iam_user_group_membership" "master_user" {
  for_each = var.user_map

  user = each.key
  groups = each.value
}
