# -- Variables --

variable "user_map" {
  description = "Map of users to group memberships."
  type        = map(list(string))
}

variable "allow_self_management" {
  description = <<EOM
Whether or not to create the 'ManageYourAccount' IAM policy and
attach it to all users in var.user_map in this account.
EOM
  type        = bool
  default     = true
}

# -- Resources --

resource "aws_iam_user" "master_user" {
  for_each = var.user_map

  name          = each.key
  force_destroy = true
}

resource "aws_iam_group_membership" "master_group" {
  for_each = transpose(var.user_map)

  name = "${each.key}-group"
  group = each.key
  users = each.value
}

resource "aws_iam_policy" "manage_your_account" {
  count = var.allow_self_management ? 1 : 0

  name        = "ManageYourAccount"
  path        = "/"
  description = "Policy for account self management"
  policy      = data.aws_iam_policy_document.manage_your_account.json
}

resource "aws_iam_policy_attachment" "manage_your_account" {
  count = var.allow_self_management ? 1 : 0

  name = "ManageYourAccount"
  users = keys(var.user_map)
  policy_arn = aws_iam_policy.manage_your_account[0].arn
}

data "aws_iam_policy_document" "manage_your_account" {
  statement {
    sid    = "AllowAllUsersToListAccounts"
    effect = "Allow"
    actions = [
      "iam:ListAccountAliases",
      "iam:ListUsers",
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
