# -- Variables --

variable "master_account_id" {
  description = "AWS account ID for the master account."
}

variable "group_role_map" {
  description = "Roles map for IAM groups, along with account types per role to grant access to."
  type = map(list(map(list(string))))
}

variable "policy_depends_on" {
  description = <<EOM
(Optional) Will force each given aws_iam_policy_attachment to verify that
the specified value (i.e. another resource, such as the respective
group_policy) exists before it is created.
EOM
  type    = any
  default = null
}

locals {
  role_group_map = transpose(
    {
      for group, perms in var.group_role_map : group => flatten([
        for perm in perms: flatten([
          for pair in setproduct(keys(perm), flatten([values(perm)])): join("", [pair[1], "Assume", pair[0]])
        ])
      ])
    }
  )
}

# -- Resources --

resource "aws_iam_group" "iam_group" {
  for_each = var.group_role_map

  name = each.key
}

resource "aws_iam_policy_attachment" "group_policy" {
  for_each = local.role_group_map
  
  name       = each.key
  groups     = each.value
  policy_arn = "arn:aws:iam::${var.master_account_id}:policy/${each.key}"

  depends_on = [var.policy_depends_on]
}

# -- Outputs --

output "group_names" {
  description = "Reference this output in order to depend on group creation being complete."
  value       = values(aws_iam_group.iam_group)[*]["name"]
}
