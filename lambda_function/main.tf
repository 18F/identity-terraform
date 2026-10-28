locals {
  lambda_dirs = merge(
    {
      source = {
        dir = var.source_dir
        zip = var.function_name
      }
    },
    var.layer_dir == "" ? {} : {
      layers = {
        dir = var.layer_dir
        zip = var.layer_name
      }
    }
  )
}

data "archive_file" "lambda" {
  for_each = local.lambda_dirs

  type             = "zip"
  source_dir       = each.value.dir
  output_path      = "${var.output_dir}/${each.value.zip}.zip"
  output_file_mode = "0644"
}

# The source_code_hash attribute is not a reliable source to track/trigger changes to Lambda functions, due to a
# discrepancy between the file's actual hash and the value retured by AWS' API/resourceAwsLambdaFunctionRead(),
# which Terraform to overwrite the value of source_code_hash in state. This is still an open issue, both with AWS
# and with the Terraform provider plugin, as described in greater detail here:
# https://github.com/hashicorp/terraform-provider-aws/issues/7385#issuecomment-728596589
#
# Since the actual files themselves are what we ACTUALLY want to track changes to -- not the paths or other
# base46-centric metadata -- this resource is used to generate a random UUID based on each file's MD5 hash, which
# will only update/change if the contents of the actual file get changed. This random_uuid resource is then used
# as a replacement trigger for the function (if its underlying code changes), and (if using) the Lambda Layer
# (i.e. if anything within var.layer_dir changes).
resource "random_uuid" "lambda" {
  for_each = local.lambda_dirs

  keepers = {
    for filename in setunion(
      toset([for setfile in fileset("${each.value.dir}/", "**") : setfile if !endswith(setfile, ".zip")]),
    ) : filename => filemd5("${each.value.dir}/${filename}")
  }
}

resource "aws_lambda_function" "lambda" {
  region = var.region

  function_name = var.function_name
  description   = var.description
  role          = aws_iam_role.lambda.arn
  filename      = data.archive_file.lambda["source"].output_path
  handler = var.handler != "" ? (
    var.handler
    ) : (
    "${replace(var.source_code_filename, "/\\..*/", "")}.${var.handler_function_name}"
  )

  memory_size                    = var.memory_size
  runtime                        = var.runtime
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions

  layers = compact(flatten([
    var.insights_layer_enabled ? module.lambda_insights[0].layer_arn : "",
    local.layer_enabled == 1 ? aws_lambda_layer_version.layer[0].arn : ""
  ]))

  environment {
    variables = var.environment_variables
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  # replace the function ONLY if the main code (tracked in random_uuid.function_main) changes at all.
  # do not track things like the ZIP file, since the file name/path/other metadata can change per-machine/per-OS.
  lifecycle {
    replace_triggered_by = [
      random_uuid.lambda["source"]
    ]
    ignore_changes = [
      filename
    ]
  }

}
