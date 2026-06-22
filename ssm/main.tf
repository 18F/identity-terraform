# SSM Session Docs
resource "aws_ssm_document" "session" {
  for_each = var.ssm_session_doc_map

  name            = "${var.env_name}-ssm-document-${each.key}"
  region          = var.region
  document_type   = "Session"
  target_type     = "/AWS::EC2::Instance"
  document_format = "YAML"
  content         = <<DOC
---
schemaVersion: '1.0'
description: "${each.value["description"]}"
sessionType: Standard_Stream
inputs:
%{if each.value["logging"]~}
  s3BucketName: "${aws_s3_bucket.ssm_logs.id}"
  s3EncryptionEnabled: true
  s3KeyPrefix: "output/session_${each.key}"
  cloudWatchLogGroupName: "${aws_cloudwatch_log_group.ssm["output/session_${each.key}"].name}"
  cloudWatchEncryptionEnabled: true
  cloudWatchStreamingEnabled: true
%{else~}
  s3EncryptionEnabled: false
  cloudWatchEncryptionEnabled: false
%{endif~}
  kmsKeyId: ${aws_kms_key.ssm.arn}
  idleSessionTimeout: ${var.session_timeout}
  runAsEnabled: true
  runAsDefaultUser: ''
  shellProfile:
    linux: 'trap "exit 0" INT TERM; ${each.value["command"]} ; exit'
DOC
}

# SSM Command Docs
resource "aws_ssm_document" "cmd" {
  for_each = var.ssm_cmd_doc_map

  name            = "${var.env_name}-ssm-cmd-${each.key}"
  region          = var.region
  document_type   = "Command"
  target_type     = "/AWS::EC2::Instance"
  document_format = "YAML"
  content = <<DOC
---
schemaVersion: "2.2"
description: "${each.value["description"]}"
parameters:
%{for ssm_parameter in each.value["parameters"]~}
  ${ssm_parameter.name}:
    type: ${ssm_parameter.type}
    default: "${ssm_parameter.default}"
    description: "${ssm_parameter.description}"
%{if ssm_parameter.pattern != null~}
    allowedPattern: '${ssm_parameter.pattern}'
%{else~}
%{if ssm_parameter.values != null~}
    allowedValues:
%{for value in ssm_parameter.values~}
    - ${value}
%{endfor~}
%{endif~}
%{endif~}
%{endfor~}
%{if !contains([for param in each.value["parameters"] : param.name], "executionTimeout")~}
  executionTimeout:
    type: String
    default: "${each.value["timeout"]}"
    description: "${join(" ", [
  "(Optional) The time in seconds for a command to complete before it is considered to have failed.",
  "Default is 3600 (1 hour). Maximum is 172800 (48 hours)."
])}"
    allowedPattern: '([1-9][0-9]{0,4})|(1[0-6][0-9]{4})|(17[0-1][0-9]{3})|(172[0-7][0-9]{2})|(172800)'
%{endif~}
mainSteps:
- action: "aws:runShellScript"
  name: "runShellScript"
  inputs:
    timeoutSeconds: "{{ executionTimeout }}"
    runCommand: ${jsonencode(each.value["command"])}
DOC
}

# SSM InteractiveCommands Session Docs
resource "aws_ssm_document" "interactive" {
  for_each = var.ssm_interactive_cmd_map

  name            = "${var.env_name}-ssm-document-${each.key}"
  region          = var.region
  document_type   = "Session"
  target_type     = "/AWS::EC2::Instance"
  document_format = "YAML"
  content         = <<DOC
---
schemaVersion: '1.0'
description: "${each.value["description"]}"
sessionType: InteractiveCommands
inputs:
%{if each.value["logging"]~}
  s3BucketName: "${aws_s3_bucket.ssm_logs.id}"
  s3EncryptionEnabled: true
  s3KeyPrefix: "output/interactive_${each.key}"
  cloudWatchLogGroupName: "${aws_cloudwatch_log_group.ssm["output/interactive_${each.key}"].name}"
  cloudWatchEncryptionEnabled: true
  cloudWatchStreamingEnabled: true
%{else~}
  s3EncryptionEnabled: false
  cloudWatchEncryptionEnabled: false
%{endif~}
  kmsKeyId: ${aws_kms_key.ssm.arn}
  idleSessionTimeout: ${var.session_timeout}
%{if length(each.value["parameters"]) >= 1~}
parameters:
%{for ssm_parameter in each.value["parameters"]~}
  ${ssm_parameter.name}:
    type: ${ssm_parameter.type}
    default: "${ssm_parameter.default}"
    description: "${ssm_parameter.description}"
%{if ssm_parameter.pattern != null~}
    allowedPattern: '${ssm_parameter.pattern}'
%{else~}
%{if ssm_parameter.values != null~}
    allowedValues:
%{for value in ssm_parameter.values~}
    - ${value}
%{endfor~}
%{endif~}
%{endif~}
%{endfor~}
%{endif~}
properties:
  linux:
    runAsElevated: ${each.value["run_elevated"]}
    commands:%{if length(each.value["command"]) == 1} "${each.value["command"][0]}"%{else} |
    %{for ssm_cmd in each.value["command"]~}
    ${ssm_cmd}
    %{endfor~}
  %{endif~}
DOC
}

# SSM Port Forwarding Docs
resource "aws_ssm_document" "portforward" {
  for_each = var.ssm_portforward_cmd_map

  name            = "${var.env_name}-ssm-document-${each.key}"
  region          = var.region
  document_type   = "Session"
  target_type     = "/AWS::EC2::Instance"
  document_format = "YAML"
  content         = <<DOC
---
schemaVersion: '1.0'
description: "${each.value["description"]}"
sessionType: Port
inputs:
%{if each.value["logging"]~}
  s3BucketName: "${aws_s3_bucket.ssm_logs.id}"
  s3EncryptionEnabled: true
  s3KeyPrefix: "output/portforward_${each.key}"
  cloudWatchLogGroupName: "${aws_cloudwatch_log_group.ssm["output/portforward_${each.key}"].name}"
  cloudWatchEncryptionEnabled: true
  cloudWatchStreamingEnabled: true
%{else~}
  s3EncryptionEnabled: false
  cloudWatchEncryptionEnabled: false
%{endif~}
  kmsKeyId: ${aws_kms_key.ssm.arn}
  idleSessionTimeout: ${var.session_timeout}
parameters:
%{for ssm_parameter in each.value["parameters"]~}
  ${ssm_parameter.name}:
    type: ${ssm_parameter.type}
    default: "${ssm_parameter.default}"
    description: "${ssm_parameter.description}"
%{if ssm_parameter.pattern != null~}
    allowedPattern: '${ssm_parameter.pattern}'
%{else~}
%{if ssm_parameter.values != null~}
    allowedValues:
%{for value in ssm_parameter.values~}
    - ${value}
%{endfor~}
%{endif~}
%{endif~}
%{endfor~}
properties:
%{for k, v in { for param in each.value["parameters"] : param.name => param.default } ~}
  ${k}: "${v}"
%{endfor~}
  type: LocalPortForwarding
DOC
}
