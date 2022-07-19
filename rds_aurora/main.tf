##### Data Sources

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "region" {
  state = "available"
}

data "aws_rds_engine_version" "family" {
  engine  = var.db_engine
  version = var.db_engine_version
}

# use aws/rds KMS key for performance insights
data "aws_kms_key" "insights" {
  key_id = "alias/aws/rds"
}

# policy for KMS key used with actual database
data "aws_iam_policy_document" "db_kms_key" {
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
        join(":", [
          "arn:aws:iam", "", data.aws_caller_identity.current.account_id,
          "role/${var.key_admin_role_name}"
        ])
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
        join(":", [
          "arn:aws:iam", "", data.aws_caller_identity.current.account_id,
          "role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
        ])
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
        join(":", [
          "arn:aws:iam", "", data.aws_caller_identity.current.account_id,
          "role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
        ])
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
  count = var.db_subnet_ids != [] ? 0 : length(keys(var.az_cidr_map))

  availability_zone = join("", [
    var.region, element(keys(var.az_cidr_map), count.index)
  ])
  cidr_block = lookup(
    var.az_cidr_map,
    element(keys(var.az_cidr_map), count.index)
  )
  map_public_ip_on_launch = false

  tags = {
    Name = join("-", [
      var.name_prefix,
      "db${element(keys(var.az_cidr_map), count.index)}_subnet",
      var.env_name
    ])
  }

  vpc_id = var.db_vpc_id
}

resource "aws_db_subnet_group" "db" {
  count = var.db_subnet_group == "" ? 1 : 0
  name  = "${var.name_prefix}-${var.env_name}-db"
  subnet_ids = (
    var.db_subnet_ids == "" ? aws_subnet.db[*].id : var.db_subnet_ids
  )
  tags = {
    Name = "${var.name_prefix}-${var.env_name} AuroraDB subnet group"
  }
}

resource "aws_security_group" "db" {
  count       = var.db_security_group == "" ? 1 : 0
  description = <<EOM
Allow inbound/outbound ${var.db_engine} traffic
within ${local.db_name} subnet in ${var.db_vpc_id} VPC.
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

  vpc_id = var.db_vpc_id
}

# DNS / Route53

resource "aws_route53_record" "writer_endpoint" {
  count   = var.internal_zone_id == "" ? 0 : 1
  zone_id = var.internal_zone_id
  name    = "${var.db_identifier}-${var.db_engine}-writer-${var.region}"

  type    = "CNAME"
  ttl     = var.route53_ttl
  records = [replace(aws_rds_cluster.aurora.endpoint, ":${var.db_port}", "")]
}

resource "aws_route53_record" "reader_endpoint" {
  count   = var.internal_zone_id == "" ? 0 : 1
  zone_id = var.internal_zone_id
  name    = "${var.db_identifier}-${var.db_engine}-reader-${var.region}"

  type    = "CNAME"
  ttl     = var.route53_ttl
  records = [replace(aws_rds_cluster.aurora.reader_endpoint, ":${var.db_port}", "")]
}

# KMS (if not importing)

resource "aws_kms_key" "db" {
  count = var.db_kms_key_id == "" ? 1 : 0

  description             = "${local.db_name} DB Key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.db_kms_key.json
}

resource "aws_kms_alias" "db" {
  count = var.db_kms_key_id == "" ? 1 : 0

  name          = "alias/${local.db_name}-db"
  target_key_id = aws_kms_key.db[count.index].key_id
}

# Monitoring role (if not importing)

resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_role == "" ? 1 : 0
  name  = "rds-monitoring-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "monitoring.rds.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.monitoring_role == "" ? 1 : 0
  role       = aws_iam_role.rds_monitoring[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# AuroraDB Cluster + Instances

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = local.db_name
  engine             = var.db_engine
  engine_version     = var.db_engine_version
  port               = var.db_port
  availability_zones = [
    for i in range(0, 3) : data.aws_availability_zones.region.names[i]
  ]
  db_subnet_group_name = (
    var.db_subnet_group == "" ? aws_db_subnet_group.db[0].name : var.db_subnet_group
  )
  vpc_security_group_ids = [(
    var.db_security_group == "" ? aws_security_group.db[0].id : var.db_security_group
  )]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.id
  db_instance_parameter_group_name = (
    var.major_upgrades ? aws_db_parameter_group.aurora.id : null
  )

  backup_retention_period      = var.retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  allow_major_version_upgrade  = var.major_upgrades
  apply_immediately            = true

  storage_encrypted = var.storage_encrypted
  kms_key_id = (
    var.db_kms_key_id == "" ? aws_kms_key.db[0].key_id : var.db_kms_key_id
  )

  # must specify password and username unless using a replication_source_identifier
  master_password               = var.rds_db_arn == "" ? var.rds_password : ""
  master_username               = var.rds_db_arn == "" ? var.rds_username : ""
  replication_source_identifier = var.rds_db_arn

  # send logs to cloudwatch
  enabled_cloudwatch_logs_exports = var.cw_logs_exports == [] ? (
    can(regex("postgresql", var.db_engine)) ? ["postgresql"] : ["general"]
  ) : var.cw_logs_exports

  tags = {
    Name = local.db_name
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
  count      = var.primary_cluster_instances # must be 1 on first creation
  identifier = "${local.db_name}-${count.index + 1}"

  cluster_identifier = aws_rds_cluster.aurora.id
  engine             = var.db_engine
  engine_version     = var.db_engine_version
  db_subnet_group_name = (
    var.db_subnet_group == "" ? aws_db_subnet_group.db[0].name : var.db_subnet_group
  )
  instance_class = var.db_instance_class

  db_parameter_group_name = aws_db_parameter_group.aurora.id

  tags = {
    Name = local.db_name
  }

  auto_minor_version_upgrade = var.auto_minor_upgrades
  apply_immediately          = true

  # enhanced monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = (
    var.monitoring_role == "" ? aws_iam_role.rds_monitoring[0].arn : var.monitoring_role
  )

  # performance insights
  performance_insights_enabled = var.pi_enabled
  performance_insights_kms_key_id = (
    var.pi_enabled ? data.aws_kms_key.insights.arn : ""
  )

}

# Application Auto Scaling (if desired)

resource "aws_appautoscaling_target" "db" {
  count = var.enable_autoscaling && var.primary_cluster_instances > 1 ? 1 : 0

  max_capacity       = var.max_cluster_instances
  min_capacity       = var.primary_cluster_instances
  resource_id        = "cluster:${aws_rds_cluster.aurora.id}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"
}

resource "aws_appautoscaling_policy" "db" {
  count = var.enable_autoscaling && var.primary_cluster_instances > 1 ? 1 : 0
  name = join(":", [
    aws_appautoscaling_target.db[count.index].resource_id,
    replace(var.autoscaling_metric_name, "RDSReaderAverage", ""),
    "ReplicaScalingPolicy"
  ])

  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.db[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.db[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.db[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.autoscaling_metric_name
    }

    target_value = var.autoscaling_metric_value
  }
}

# Parameter Groups

resource "aws_rds_cluster_parameter_group" "aurora" {
  name        = "${local.db_name}-${replace(local.pgroup_family, ".", "")}-cluster"
  family      = local.pgroup_family
  description = "${local.pgroup_family} parameter group for ${local.db_name} cluster"

  dynamic "parameter" {
    for_each = var.apg_cluster_pgroup_params
    iterator = pblock

    content {
      name         = pblock.value.name
      value        = pblock.value.value
      apply_method = lookup(pblock.value, "method", "immediate")
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "aurora" {
  name        = "${local.db_name}-${replace(local.pgroup_family, ".", "")}-db"
  family      = local.pgroup_family
  description = "${local.pgroup_family} parameter group for ${local.db_name} instances"

  dynamic "parameter" {
    for_each = var.apg_db_pgroup_params
    iterator = pblock

    content {
      name         = pblock.value.name
      value        = pblock.value.value
      apply_method = lookup(pblock.value, "method", "immediate")
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}
