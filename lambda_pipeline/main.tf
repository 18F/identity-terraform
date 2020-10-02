data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  stack_name         = "${var.env}-${var.cf_stack_name}"
  build_project_name = "${var.env}-${var.project_name}"
}
