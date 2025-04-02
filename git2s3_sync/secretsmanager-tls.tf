ephemeral "ephemeraltls_private_key" "git2s3" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_secretsmanager_secret" "ssh_key_pair" {
  name                    = local.ssh_key_path
  recovery_window_in_days = 0
  kms_key_id              = aws_kms_key.ssh_key_pair.key_id
}

resource "aws_secretsmanager_secret_version" "ssh_key_pair" {
  secret_id = aws_secretsmanager_secret.ssh_key_pair.id
  secret_string_wo = jsonencode({
    PRIVATE_KEY = ephemeral.ephemeraltls_private_key.git2s3.private_key_openssh,
    PUBLIC_KEY  = ephemeral.ephemeraltls_private_key.git2s3.public_key_openssh
  })
  secret_string_wo_version = var.ssh_key_secret_version

  lifecycle {
    ignore_changes = [secret_string_wo]
  }
}
