locals {
  all_docs_and_cmds = merge(
    { for k, v in var.ssm_cmd_doc_map : "cmd_${k}" => v },
    { for k, v in var.ssm_interactive_cmd_map : "interactive_${k}" => v },
    { for k, v in var.ssm_portforward_cmd_map : "portforward_${k}" => v },
    { for k, v in var.ssm_session_doc_map : "session_${k}" => v },
  )

  # list of 'invocation' CloudWatch Log Groups, tracking any time any SSM doc is invoked
  invocation_log_list = formatlist("invocations/%s", keys(local.all_docs_and_cmds))

  # list of 'output' CloudWatch Log Groups, to log from any command/doc/etc. where logging = true
  output_log_list = formatlist("output/%s", [
    for ssm_doc, configs in local.all_docs_and_cmds : ssm_doc if configs.logging
  ])
}

# create Log Groups for 1) invocations of all SSM docs, and 2) outputs of any where logging = true
resource "aws_cloudwatch_log_group" "ssm" {
  for_each = toset(flatten([local.invocation_log_list, local.output_log_list]))

  name              = "/aws/ssm/${var.env_name}/${each.key}"
  region            = var.region
  retention_in_days = var.cloudwatch_retention_days
  skip_destroy      = var.prevent_tf_log_deletion
  kms_key_id        = aws_kms_key.ssm.arn
}

# log invocations of SSM documents, even if logging = false
resource "aws_cloudwatch_event_rule" "ssm" {
  for_each = {
    for log in local.invocation_log_list : log => replace("${var.env_name}-ssm-${replace(
    split("/", log)[1], "/interactive|portforward|session/", "document")}", "_", "-")
  }

  name        = replace("${var.env_name}-ssm-${each.key}", "/[_\\/]/", "-")
  region      = var.region
  description = "Capture when SSM document '${each.value}' is invoked"

  event_pattern = jsonencode({
    source = [
      "aws.ssm"
    ]
    detail-type = [
      "AWS API Call via CloudTrail"
    ]
    detail = {
      eventSource = [
        "ssm.amazonaws.com"
      ],
      requestParameters = {
        documentName = [
          each.value
        ]
      },
      # SendCommand
      eventName = startswith(each.key, "invocations/cmd") ? [
        "SendCommand",
        "CancelCommand"
        ] : [
        "StartSession",
        "ResumeSession",
        "TerminateSession"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "ssm" {
  for_each = toset(local.invocation_log_list)

  rule      = aws_cloudwatch_event_rule.ssm[each.key].name
  region    = var.region
  target_id = replace("${var.env_name}-ssm-${each.key}", "/[_\\/]/", "-")
  arn       = aws_cloudwatch_log_group.ssm[each.key].arn
}


removed {
  from = aws_cloudwatch_log_group.ssm_cmd_logs
  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_cloudwatch_log_group.ssm_session_logs
  lifecycle {
    destroy = false
  }
}
