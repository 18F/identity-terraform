locals {
  layer_enabled = alltrue([
    length(var.layer_dir) > 0,
    length(var.layer_name) > 0,
    length(var.layer_s3_bucket) > 0,
  ]) ? 1 : 0
}

module "lambda_insights" {
  count  = var.insights_layer_enabled ? 1 : 0
  source = "github.com/18F/identity-terraform//lambda_insights?ref=5c1a8fb0ca08aa5fa01a754a40ceab6c8075d4c9"
  #source = "../../../../identity-terraform/lambda_insights"

  region = var.region
}

resource "aws_s3_object" "lambda_layer" {
  count = local.layer_enabled

  key = join("/", [
    for item in [var.function_name, join(".", [var.layer_name, "zip"])] : item if item != null && item != ""
  ])
  bucket             = var.layer_s3_bucket
  region             = var.region
  source             = data.archive_file.lambda["layers"].output_path
  checksum_algorithm = "SHA256"

  depends_on = [
    data.archive_file.lambda["layers"]
  ]

  lifecycle {
    replace_triggered_by = [
      random_uuid.lambda["layers"]
    ]
    ignore_changes = [
      source
    ]
  }
}

resource "aws_lambda_layer_version" "layer" {
  count = local.layer_enabled

  layer_name       = var.layer_name
  source_code_hash = aws_s3_object.lambda_layer.checksum_sha256
  s3_bucket        = aws_s3_object.lambda_layer.bucket
  s3_key           = aws_s3_object.lambda_layer.key
  compatible_runtimes = [
    var.runtime
  ]
}
