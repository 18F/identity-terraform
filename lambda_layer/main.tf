module "layer_archive" {
  source = "github.com/GSA-TTS/identity-terraform//null_archive?ref=720ecb051f472bd3a62c16422bb05b4db4514352"
  #source = "../null_archive"

  source_code_filename = var.source_code_filename
  source_dir           = var.source_dir
  zip_filename         = var.zip_filename
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = module.layer_archive.zip_output_path
  layer_name = var.layer_name

  compatible_runtimes = var.compatible_runtimes
  source_code_hash    = module.layer_archive.zip_output_base64sha256

}
