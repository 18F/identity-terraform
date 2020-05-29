# -- Variables --

variable "master_account_id" {
  description = "AWS account ID for the master account."
}

variable "group_role_map" {
  description = "Roles map for IAM groups, along with account types per role to grant access to."
  type = map(list(map(list(string))))
}

locals {
  group_account_map = [
    for line in flatten([
      for item, access in
      {
        for group, perms in var.group_role_map : group => flatten([
          for perm in perms: flatten([
            for pair in setproduct(keys(perm), flatten([values(perm)])): join("", [pair[1], "Assume", pair[0]])
          ])
        ])
      }: formatlist("%s %s", item, access)
    ]): split(" ", line)
  ]
}

# -- Resources --

resource "aws_iam_group" "iam_group" {
  for_each = var.group_role_map

  name = each.key
}

resource "aws_iam_group_policy_attachment" "iam_group_policies" {
  count = length(local.group_account_map)
  
  group = element(local.group_account_map[count.index],0)
  policy_arn = "arn:aws:iam::${var.master_account_id}:policy/${element(local.group_account_map[count.index],1)}"
}