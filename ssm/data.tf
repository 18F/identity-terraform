data "aws_caller_identity" "current" {
}

# Policy and roles to permit SSM access / actions on EC2 instances, and to allow them to send metrics and logs to CloudWatch
data "aws_iam_policy_document" "ssm_access_role_policy" {
  # Basic
  statement {
    sid = "SSMCoreAccess"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:GetMessages",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:SendReply",
      "ssm:ListInstanceAssociations"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid = "CloudWatchLogsDescribeAccessForSSM"
    actions = [
      "logs:DescribeLogGroups",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid = "CloudWatchLogsWriteAccessForSSM"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [
      for logname in toset(flatten([local.invocation_log_list, local.output_log_list])) : join(":",
        [
          "arn:aws:logs",
          var.region,
          data.aws_caller_identity.current.account_id,
          "log-group",
          "/aws/ssm/${var.env_name}/${logname}*"
        ]
      )
    ]
  }
  # S3
  statement {
    sid = "S3LoggingAccessForSSM"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.ssm_logs.arn}/*"
    ]
  }
  # KMS
  statement {
    sid = "KMSDecryptionAccess"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [
      aws_kms_key.ssm.arn
    ]
  }
}
