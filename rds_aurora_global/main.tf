##### Data Sources

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "region" {
  state = "available"
}

data "aws_rds_engine_version" "family" {
  engine  = var.db_engine
  version = var.db_engine_version
}

data "aws_iam_policy_document" "db" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    actions = [
      "kms:*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "Allow access for Key Administrators"
    effect = "Allow"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]
    resources = [
      "*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.key_admin_role_name}"
      ]
    }
  }

  statement {
    sid    = "Allow RDS Access"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      "*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
      ]
    }
  }

  statement {
    sid    = "Allow attachment of resources"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]
    resources = [
      "*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS",
      ]
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"

      values = [
        "true",
      ]
    }
  }
}

##### Resources

# Networking (if not importing)

resource "aws_subnet" "db" {
  for_each = local.db_subnets

  availability_zone       = "${var.region}${each.key}"
  cidr_block              = each.value
  map_public_ip_on_launch = false

  tags = {
    Name = join("-", [
      var.name, "db${index(keys(local.db_subnets), each.key) + 1}_subnet", var.env_name
    ])
  }

  vpc_id = var.vpc_id
}

resource "aws_db_subnet_group" "db" {
  count      = var.db_subnet_group == "" ? 1 : 0
  name       = local.subnet_group
  subnet_ids = var.db_subnet_ids == [] ? [aws_subnet.db[*].id] : var.db_subnet_ids
  tags = {
    Name = "${var.name_prefix}-${var.env_name} AuroraDB subnet group"
  }
}

resource "aws_security_group" "db" {
  count       = var.db_security_group == "" ? 1 : 0
  description = <<EOM
Allow inbound and outbound ${var.db_engine} traffic with ${var.db_id} subnet in VPC.
EOM

  egress = []

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = var.ingress_security_group_ids
  }

  name = "${var.name_prefix}-db-${var.env_name}"

  tags = {
    Name = "${var.name_prefix}-db_security_group-${var.env_name}"
  }

  vpc_id = var.vpc_id
}

# KMS (if not importing)

resource "aws_kms_key" "db" {
  count = var.db_kms_key == "" ? 1 : 0

  description             = "${var.name_prefix}-${var.env_name}-${var.db_id} DB Key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.db.json
}

resource "aws_kms_alias" "db" {
  count = var.db_kms_key == "" ? 1 : 0

  name          = "alias/${var.name_prefix}-${var.env_name}-${var.db_id}-db"
  target_key_id = aws_kms_key.db[count.index].key_id
}


# AuroraDB Cluster + Instances

resource "aws_rds_cluster" "aurora" {
  cluster_identifier   = "${var.name_prefix}-${var.env_name}-${var.db_id}"
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  port                 = var.db_port
  availability_zones   = data.aws_availability_zones.region.names
  db_subnet_group_name = local.subnet_group
  vpc_security_group_ids = [
    var.db_security_group == "" ? aws_security_group.db.id : var.db_security_group
  ]

  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.aurora.id
  db_instance_parameter_group_name = var.major_upgrades ? aws_db_parameter_group.aurora.id : null

  backup_retention_period      = var.retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  allow_major_version_upgrade  = var.major_upgrades
  apply_immediately            = true

  storage_encrypted = true
  kms_key_id        = var.db_kms_key == "" ? aws_kms_key.db.key_id : var.db_kms_key

  # must specify password and username unless using a replication_source_identifier
  master_password               = var.rds_password
  master_username               = var.rds_username
  replication_source_identifier = var.rds_db_arn

  # send logs to cloudwatch
  enabled_cloudwatch_logs_exports = var.cw_logs_exports == [] ? (
    var.db_engine == "postgresql" ? ["postgresql"] : ["general"]
  ) : var.cw_logs_exports

  tags = {
    Name = "${var.name_prefix}-${var.env_name}-${var.db_id}"
  }

  #lifecycle {
  #  ignore_changes = [
  #    replication_source_identifier
  #  ]
  #}

  # To properly delete this cluster via Terraform:
  # 1. Uncomment `skip_final_snapshot = true` and
  #    comment out `deletion_protection = true` below.
  # 2. Perform a targeted 'apply' (e.g. "-target=aws_rds_cluster.aurora")
  #    to remove deletion protection + disable requiring a final snapshot.
  # 3. Perform a 'destroy' operation as needed.

  #skip_final_snapshot = true
  deletion_protection = true
}

resource "aws_rds_cluster_instance" "aurora" {
  count = var.primary_cluster_instances # must be 1 on first creation
  identifier = join("-", [
    var.name_prefix, var.env_name, var.db_id, "${count.index + 1}"
  ])
  cluster_identifier = aws_rds_cluster.aurora.id
  engine             = var.db_engine
  engine_version     = var.db_engine_version

  instance_class          = var.db_instance_class
  db_subnet_group_name    = local.subnet_group
  db_parameter_group_name = aws_db_parameter_group.aurora.id

  tags = {
    Name = "${var.name_prefix}-${var.env_name}-${var.db_id}"
  }

  auto_minor_version_upgrade = var.auto_minor_upgrades
  apply_immediately          = true

  # enhanced monitoring
  monitoring_interval             = var.rds_enhanced_monitoring_interval
  monitoring_role_arn             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.rds_monitoring_role_name}"
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? data.aws_kms_key.rds_alias.arn : ""

}

# Parameter Groups

resource "aws_rds_cluster_parameter_group" "aurora" {
  name = join("-", [
    var.name_prefix, var.env_name, var.db_id,
    "${var.db_engine}${replace(local.rds_engine_version_short, ".", "")}", "cluster"
  ])
  family      = "${var.db_engine}${local.db_engine_version_short}"
  description = <<EOM
${var.db_engine}${local.db_engine_version_short} parameter group
for ${var.name_prefix}-${var.env_name}-${var.db_id} Aurora RDS cluster
EOM

  dynamic "parameter" {
    for_each = var.apg_cluster_pgroup_params
    iterator = pblock

    content {
      name         = pblock.value.name
      value        = pblock.value.value
      apply_method = pblock.value.apply_method
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "aurora" {
  name = join("-", [
    var.name_prefix, var.env_name, var.db_id,
    "${var.db_engine}${replace(local.rds_engine_version_short, ".", "")}", "db"
  ])
  family      = "${var.db_engine}${local.db_engine_version_short}"
  description = <<EOM
${var.db_engine}${local.db_engine_version_short} parameter group
for ${var.name_prefix}-${var.env_name}-${var.db_id} Aurora DB instances
EOM

  dynamic "parameter" {
    for_each = var.apg_db_pgroup_params
    iterator = pblock

    content {
      name         = pblock.value.name
      value        = pblock.value.value
      apply_method = pblock.value.apply_method
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}
