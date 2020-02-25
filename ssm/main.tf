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
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:aws/ssm/${var.env_name}/*",
    ]
  }
}

# policy to allow ssm access to ec2
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# -- Resources --
resource "aws_iam_role" "ec2_ssm_instance_profile_role" {
  count              = var.enabled
  name               = "${var.env_name}_ec2_ssm_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "ec2_ssm_instance_profile_policy" {
  count              = var.enabled
  name               = "${var.env_name}_ec2_ssm_policy"
  role               = aws_iam_role.ec2_ssm_instance_profile_role[0].id
  policy             = data.aws_iam_policy_document.ssm.json
}

resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  count              = var.enabled
  name               = "${var.env_name}_ec2_ssm_instance_profile"
  role               = aws_iam_role.ec2_ssm_instance_profile_role[0].name
}
