# -- Variables --

variable "lambda_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "SnsToSlack"
}

variable "lambda_description" {
  description = "Lambda description"
  type        = string
  default     = "Sends a message sent to an SNS topic to Slack."
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function"
  type        = number
  default     = 120
}

variable "lambda_memory" {
  description = "Memory allocated to Lambda function, 128MB to 3,008MB in 64MB increments"
  type        = number
  default     = 128
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.6"
}

variable "slack_webhook_url" {
  description = "Slack Webhook URL."
  type        = string
}

variable "slack_channel" {
  description = "Name of the Slack channel to send messages to. DO NOT include the # sign."
  type        = string
}

variable "slack_username" {
  description = "Displayed username of the posted message."
  type        = string
}

variable "slack_icon" {
  description = "Displayed icon used by Slack for the message."
  type        = string
}

variable "slack_topic_arn" {
  description = "ARN of the SNS topic for the Lambda to subscribe to."
  type        = string
}

# -- Locals --

locals {
  slack_lambda_code = <<-EOT
    #!/usr/bin/python3.6
    import urllib3
    import json
    http = urllib3.PoolManager()
    def lambda_handler(event, context):
        url = "${var.slack_webhook_url}"
        msg = {
            "channel": "#${var.slack_channel}",
            "username": "${var.slack_username}",
            "text": event['Records'][0]['Sns']['Message'],
            "icon_emoji": "${var.slack_icon}"
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
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.slack_lambda.arn
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
  name              = "/aws/lambda/slack_lambda/${var.lambda_name}"
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
  publish          = true

  # as a result of local.slack_lambda_code being used as a generator for the
  # lambda_function.zip file, the last_modified and source_code_hash values
  # will change every single time plan/apply is run. this is a hacky workaround
  # to not rely upon external files for lambda_function.zip or lambda.py, and
  # to continue using local.slack_lambda_code instead.

  ######## COMMENT THIS BLOCK OUT IF YOU'VE UPDATED YOUR SLACK WEBHOOK #######
  lifecycle {
    ignore_changes = [
      source_code_hash,
      last_modified,
    ]
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
