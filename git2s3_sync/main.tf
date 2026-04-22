data "aws_caller_identity" "current" {
}

data "github_ip_ranges" "ips" {
}

data "aws_region" "current" {
}

locals {
  ssh_key_path = "${var.git2s3_project_name}-ssh-key"
}
