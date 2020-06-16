# -- Variables --

variable "user_map" {
  description = "Map of users to group memberships."
  type        = map(list(string))
}

variable "group_depends_on" {
  description = <<EOM
(Optional) Will force each given aws_iam_group_membership to verify that
the specified value (i.e. another resource, such as the respective
group) exists before it is created.
EOM
  type    = any
  default = null
}

# -- Resources --

resource "aws_iam_user" "master_user" {
  for_each = var.user_map

  name          = each.key
  force_destroy = true
}

resource "aws_iam_group_membership" "master_group" {
  for_each = transpose(var.user_map)

  name       = "${each.key}-group"
  group      = each.key
  users      = each.value
  depends_on = [
    aws_iam_user.master_user,
    var.group_depends_on
  ]
}

resource "aws_iam_policy" "manage_your_account" {
  name        = "ManageYourAccount"
  path        = "/"
  description = "Policy for account self management"
  policy      = data.aws_iam_policy_document.manage_your_account.json
}

resource "aws_iam_user_policy_attachment" "manage_your_account" {
  for_each = aws_iam_user.master_user
  
  user       = each.key
  policy_arn = aws_iam_policy.manage_your_account.arn
}

data "aws_iam_policy_document" "manage_your_account" {
  statement {
    sid    = "AllowAllUsersToListAccounts"
    effect = "Allow"
    actions = [
      "iam:ListAccountAliases",
      "iam:ListUsers",
      "iam:ListAttachedGroupPolicies",
      "iam:ListVirtualMFADevices",
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid    = "AllowAllUsersToListIAMResourcesWithMFA"
    effect = "Allow"
    actions = [
      "iam:ListPolicies",
      "iam:GetPolicyVersion",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true",
      ]
    }
  }
  statement {
    sid    = "AllowIndividualUserToSeeAndManageOnlyTheirOwnAccountInformation"
    effect = "Allow"
    actions = [
      "iam:ChangePassword",
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
      "iam:DeleteAccessKey",
      "iam:DeleteLoginProfile",
      "iam:GetLoginProfile",
      "iam:GetUser",
      "iam:GetAccessKeyLastUsed",
      "iam:ListAccessKeys",
      "iam:UpdateAccessKey",
      "iam:UpdateLoginProfile",
      "iam:ListSigningCertificates",
      "iam:DeleteSigningCertificate",
      "iam:UpdateSigningCertificate",
      "iam:UploadSigningCertificate",
      "iam:ListSSHPublicKeys",
      "iam:GetSSHPublicKey",
      "iam:DeleteSSHPublicKey",
      "iam:UpdateSSHPublicKey",
      "iam:UploadSSHPublicKey",
      "iam:ListUserPolicies",
      "iam:ListAttachedUserPolicies",
      "iam:ListGroupsForUser",
    ]
    resources = [
      "arn:aws:iam::*:user/$${aws:username}",
    ]
  }
  statement {
    sid    = "AllowIndividualUserToListOnlyTheirOwnMFA"
    effect = "Allow"
    actions = [
      "iam:ListMFADevices",
    ]
    resources = [
      "arn:aws:iam::*:mfa/*",
      "arn:aws:iam::*:user/$${aws:username}",
    ]
  }
  statement {
    sid    = "AllowIndividualUserToManageTheirOwnMFA"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
    ]
    resources = [
      "arn:aws:iam::*:mfa/$${aws:username}",
      "arn:aws:iam::*:user/$${aws:username}",
    ]
  }
  statement {
    sid    = "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA"
    effect = "Allow"
    actions = [
      "iam:DeactivateMFADevice",
    ]
    resources = [
      "arn:aws:iam::*:mfa/$${aws:username}",
      "arn:aws:iam::*:user/$${aws:username}",
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true",
      ]
    }
  }
  statement {
    sid    = "BlockMostAccessUnlessSignedInWithMFA"
    effect = "Deny"
    actions = [
      "iam:DeleteVirtualMFADevice",
      "iam:DeleteLoginProfile",
      "iam:DeleteAccessKey",
      "iam:DeactivateMFADevice",
      "iam:ResyncMFADevice",
      "iam:ListSSHPublicKeys",
      "iam:DeleteSSHPublicKey",
      "iam:UpdateSSHPublicKey",
      "iam:UploadSSHPublicKey",
      "iam:ListAccessKeys",
      "iam:GetAccessKeyLastUsed",
      "iam:ListServiceSpecificCredentials",
      "iam:GetAccountSummary",
      "iam:GetUser",
      "iam:ListUserPolicies",
      "iam:ListAttachedUserPolicies",
      "iam:ListGroupsForUser",
      "iam:GetPolicyVersion",
      "sts:AssumeRole",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "false",
      ]
    }
  }
}
