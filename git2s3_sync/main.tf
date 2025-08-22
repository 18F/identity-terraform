data "aws_caller_identity" "current" {
}

data "github_ip_ranges" "ips" {
}

data "aws_region" "current" {
}

locals {
  log_bucket = var.log_bucket_name != "" ? var.log_bucket_name : join(".",
    [
      var.bucket_name_prefix,
      "s3-access-logs",
      "${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
    ]
  )

  inventory_bucket = var.inventory_bucket_name != "" ? var.inventory_bucket_name : join(".",
    [
      var.bucket_name_prefix,
      "s3-inventory",
      "${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
    ]
  )

  ssh_key_path = "${var.git2s3_project_name}-ssh-key"
}
