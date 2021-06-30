resource "aws_codecommit_repository" "buildspec" {
    count = var.build_account == data.aws_caller_identity.current.account_id ? 1 : 0
    repository_name = local.build_project_name
    description     = "Repository for buildspec.yml"
}
