data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    sid    = "CloudTrailAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      join(":", [
        "${aws_cloudwatch_log_group.cloudtrail_default.arn}:log-stream",
        "${data.aws_caller_identity.current.account_id}_CloudTrail_${data.aws_region.current.region}*"
      ])
    ]
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch_logs" {
  name               = "CloudTrail_CloudWatchLogs_Role"
  description        = "Allows AWS CloudTrail to have access to Cloudwatch logs."
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_logs" {
  name   = "CloudTrail_CloudWatchLogs_Role"
  role   = aws_iam_role.cloudtrail_cloudwatch_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_logs.json
}
