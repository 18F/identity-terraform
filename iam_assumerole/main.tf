data "aws_iam_policy_document" "main" {
  count = length(var.iam_policies)

  source_policy_documents = var.iam_policies[count.index]
}

data "aws_iam_policy" "custom" {
  for_each = toset(var.custom_iam_policies)

  name = each.key
}

resource "aws_iam_policy" "main" {
  count = length(var.iam_policies)

  name        = "${var.role_name}${count.index + 1}"
  description = "Policy ${count.index + 1} for ${var.role_name} role"
  policy      = data.aws_iam_policy_document.main[count.index].json

  # This precondition check validates IAM policies meet maximum length requirements and fails fast (in terraform plan
  # operations). aws_iam_policy_document.json returns non-minified json, but aws_iam_policy consumes the input as a
  # minified json structure. The jsondecode() and jsonencode() operations result in the minified json strucutre.
  lifecycle {
    precondition {
      condition = length(
        jsonencode(jsondecode(data.aws_iam_policy_document.main[count.index].json))
      ) <= 6144
      error_message = <<EOM
The IAM policy ${var.role_name}${count.index + 1} exceeds the maximum allowed length (6144 characters.)
Current Length: ${length(jsonencode(jsondecode(data.aws_iam_policy_document.main[count.index].json)))}
EOM
    }
  }
}

resource "aws_iam_role" "assumable" {
  name                 = var.role_name
  description          = var.role_description
  tags                 = var.role_tags
  assume_role_policy   = var.master_assumerole_policy
  path                 = "/"
  max_session_duration = var.role_duration #seconds
  permissions_boundary = var.permissions_boundary_policy_arn
}

resource "aws_iam_role_policy_attachment" "main" {
  count = length(var.iam_policies)

  role       = aws_iam_role.assumable.name
  policy_arn = aws_iam_policy.main[count.index].arn
}

resource "aws_iam_role_policy_attachment" "custom" {
  for_each = data.aws_iam_policy.custom

  role       = aws_iam_role.assumable.name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachments_exclusive" "managed" {
  role_name = aws_iam_role.assumable.name
  policy_arns = compact(flatten([
    [for policy in aws_iam_policy.main : policy.arn],
    [for policy in data.aws_iam_policy.custom : policy.arn],
  ]))
}

output "role_name" {
  value = aws_iam_role.assumable.name
}

output "role_unique_id" {
  value = aws_iam_role.assumable.unique_id
}

# remove in a subsequent MR/release

moved {
  from = aws_iam_policy.iam_role_policy[0]
  to   = aws_iam_policy.main[0]
}

moved {
  from = aws_iam_role.iam_assumable_role[0]
  to   = aws_iam_role.assumable
}

moved {
  from = aws_iam_role_policy_attachment.policy_attachment_custom
  to   = aws_iam_role_policy_attachment.custom
}

moved {
  from = aws_iam_role_policy_attachment.policy_attachment_main[0]
  to   = aws_iam_role_policy_attachment.main[0]
}
