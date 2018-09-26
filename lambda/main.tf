resource "aws_lambda_function" "lambda" {
    s3_bucket = "${var.source_bucket_name}"
    s3_key = "${var.source_key}"
    function_name = "${var.env_name}-${var.lambda_name}"
    description = "${var.lambda_description}"
    memory_size = "${var.lambda_memory}"
    timeout = "${var.lambda_timeout}"
    role = "${var.lambda_role_arn}"
    handler = "${var.lambda_handler}"
    source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
    runtime = "${var.lambda_runtime}"
}