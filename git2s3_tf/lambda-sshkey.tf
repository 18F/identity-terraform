data "aws_iam_policy_document" "lambda_sshkey_access" {
  statement {
    sid    = "S3PutKeys"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = formatlist(
      "arn:aws:s3:::${var.secrets_bucket}/${local.ssh_key_path}/%s",
      ["enc_key", "enc_pub"]
    )
  }

  statement {
    sid    = "KMSEncryptSSHKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt"
    ]
    resources = [
      aws_kms_key.lambda_sshkey.arn
    ]
  }
}

module "lambda_sshkey" {
  source = "github.com/18F/identity-terraform//lambda_function?ref=026f69d0a5e2b8af458888a5f21a72d557bbe1fe"
  #source = "../lambda_function"

  region               = data.aws_region.current.name
  function_name        = local.ssh_key_path
  description          = "Creates an SSH key for ${var.git2s3_project_name} to access GitHub"
  source_code_filename = "lambda_function.py"
  source_dir           = "${path.module}/lambda_sshkey/"
  runtime              = "python3.9"
  timeout              = 300
  memory_size          = 128

  environment_variables = {}

  cloudwatch_retention_days = var.cloudwatch_retention_days
  insights_enabled          = false
  alarm_actions             = []

  lambda_iam_policy_document = data.aws_iam_policy_document.lambda_sshkey_access.json
}

# run once when creating module in order to create SSH key, encrypt, and place in bucket
resource "aws_lambda_invocation" "lambda_sshkey" {
  function_name = module.lambda_sshkey.function_name

  input = jsonencode({
    KeyBucket  = var.secrets_bucket
    BucketPath = local.ssh_key_path
    Region     = data.aws_region.current.name
    KMSKey     = aws_kms_key.lambda_sshkey.id
  })

  lifecycle_scope = "CRUD"
}
