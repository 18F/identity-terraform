locals {
  enable_trigger = (
    var.schedule_expression == "" && var.event_pattern != "") || (
  var.schedule_expression != "" && var.event_pattern == "")
}

resource "aws_cloudwatch_event_rule" "lambda" {
  count               = local.enable_trigger ? 1 : 0
  name                = var.function_name
  description         = "Trigger ${var.function_name} from EventBridge"
  schedule_expression = var.schedule_expression
  event_pattern       = var.event_pattern
}

resource "aws_cloudwatch_event_target" "lambda" {
  count = local.enable_trigger ? 1 : 0
  rule  = aws_cloudwatch_event_rule.lambda[0].name
  arn   = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "lambda" {
  count         = local.enable_trigger ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda[0].arn
}
