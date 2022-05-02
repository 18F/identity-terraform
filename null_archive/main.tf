# -- Data Sources --

data "archive_file" "lambda" {
  depends_on  = [null_resource.source_hash_check]
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${var.zip_filename}"
}

# -- Resources --

resource "null_resource" "source_hash_check" {
  triggers = {
    source_hash = filebase64sha256("${var.source_dir}/${var.source_code_filename}")
  }
}
