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
  default     = "python3.12"
}

variable "slack_webhook_url_parameter" {
  description = "Slack Webhook URL SSM Parameter."
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

variable "slack_alarm_emoji" {
  description = "Emoji used by Slack for a CloudWatch ALARM message."
  type        = string
  default     = ":large_red_square:"
}

variable "slack_ok_emoji" {
  description = "Emoji used by Slack for a CloudWatch OK message."
  type        = string
  default     = ":large_green_square:"
}

variable "slack_topic_arn" {
  description = "ARN of the SNS topic for the Lambda to subscribe to."
  type        = string
}
