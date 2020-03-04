# -- Variables --
# Remove this variable when modules support count
# https://github.com/hashicorp/terraform/issues/953
variable "enabled" {
  default     = 1
  description = "Whether this module is enabled (hack around modules not supporting count)"
}

variable "region" {
  default     = "us-west-2"
  description = "AWS Region"
}

variable "env_name" {
  description = "Environment name, for prefixing the ssm logstream"
}

# -- Data --
data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "ssm" {
  statement {
    sid = "ssmmessages"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ssm:UpdateInstanceInformation",
    ]

    resources = [
      "*",
    ]
  }
  statement {
    sid = "ssmlogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "*",
    ]
  }
}

# -- Resources --
resource "aws_iam_policy" "ec2_ssm_policy" {
  count       = var.enabled
  name        = "${var.env_name}_ec2_ssm_policy"
  path        = "/"
  description = "Allow SSM session management"
  policy      = data.aws_iam_policy_document.ssm.json
}

# -- Outputs --
output "ssm_iam_policy_arn" {
  value = aws_iam_policy.ec2_ssm_policy[0].arn
}
