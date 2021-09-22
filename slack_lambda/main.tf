# -- Locals --

locals {
  slack_lambda_code = <<-EOT
    #!/usr/bin/python3.8
    import boto3
    import urllib3
    import json
    import os
    ssm = boto3.client('ssm')
    slackChannel = os.environ['slack_channel']
    slackUsername = os.environ['slack_username']
    slackIcon = os.environ['slack_icon']
    slackUrlParam = os.environ['slack_webhook_url_parameter']
    parameter = ssm.get_parameter(Name=slackUrlParam, WithDecryption=True)
    http = urllib3.PoolManager()
    def lambda_handler(event, context):
        url = parameter['Parameter']['Value']
        eventmsg = event['Records'][0]['Sns']['Message']
        try:
          data = json.loads(eventmsg)
          if 'detailType' in data and data['detailType'] == 'CodePipeline Pipeline Execution State Change':
            msgtext = 'auto-terraform:  ' + data['detail']['pipeline'] + ' pipeline ' + data['detail']['state'] + ' with execution ID ' + data['detail']['execution-id']
          elif 'AlarmName' in data and 'AlarmDescription' in data:
```suggestion
            msgtext = '\n'.join(' '.join(pair) for pair in [
              ['*Alarm has gone off!*'],
              ['*' + data['AlarmName'] + '*', data['AlarmDescription']],
              [data['NewStateReason']],
              ['*Time*:', data['StateChangeTime']],
              ['*Region*:', data['Region']])
          else:
            msgtext = eventmsg
        except:
          msgtext = eventmsg
        msg = {
            "channel": slackChannel,
            "username": slackUsername,
            "text": msgtext,
            "icon_emoji": slackIcon
        }
        encoded_msg = json.dumps(msg).encode('utf-8')
        resp = http.request('POST',url, body=encoded_msg)
        print({
            "message": event['Records'][0]['Sns']['Message'], 
            "status_code": resp.status, 
            "response": resp.data
        })
  EOT
}

# -- Data Sources --

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    sid    = "assume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid    = "AllowWritesToCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.slack_lambda.arn}:*"
    ]
  }
  statement {
    sid    = "SSM"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.slack_webhook_url_parameter}"
    ]
  }
}

data "archive_file" "lambda_function" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = local.slack_lambda_code
    filename = "lambda_function.py"
  }
}

# -- Resources --

resource "aws_cloudwatch_log_group" "slack_lambda" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 365
}

resource "aws_lambda_function" "slack_lambda" {
  filename         = data.archive_file.lambda_function.output_path
  function_name    = var.lambda_name
  description      = var.lambda_description
  role             = aws_iam_role.slack_lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.6"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  publish          = false

  environment {
    variables = {
      slack_webhook_url_parameter = var.slack_webhook_url_parameter
      slack_channel               = var.slack_channel,
      slack_username              = var.slack_username,
      slack_icon                  = var.slack_icon
    }
  }
}

resource "aws_iam_role" "slack_lambda" {
  name_prefix        = var.lambda_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "slack_lambda" {
  name   = var.lambda_name
  role   = aws_iam_role.slack_lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_lambda_permission" "allow_sns_trigger" {
  statement_id  = "AllowExecutionBySNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = var.slack_topic_arn
}

resource "aws_sns_topic_subscription" "sns_to_lambda" {
  topic_arn = var.slack_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_lambda.arn
}
