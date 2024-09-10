resource "aws_config_config_rule" "cloudtrail_security_trail_enabled" {
  name = "fedramp-cloudtrail-security-trail-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUDTRAIL_SECURITY_TRAIL_ENABLED"
  }
}

resource "aws_config_config_rule" "dynamodb_in_backup_plan" {
  name = "fedramp-dynamodb-in-backup-plan"
  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_IN_BACKUP_PLAN"
  }
}

resource "aws_config_config_rule" "dynamodb_table_encrypted_kms" {
  name = "fedramp-dynamodb-table-encrypted-kms"
  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_TABLE_ENCRYPTED_KMS"
  }
  scope {
    compliance_resource_types = [
      "AWS::DynamoDB::Table"
    ]
  }
}

resource "aws_config_config_rule" "ebs_in_backup_plan" {
  name = "fedramp-ebs-in-backup-plan"
  source {
    owner             = "AWS"
    source_identifier = "EBS_IN_BACKUP_PLAN"
  }
}

resource "aws_config_config_rule" "efs_in_backup_plan" {
  name = "fedramp-efs-in-backup-plan"
  source {
    owner             = "AWS"
    source_identifier = "EFS_IN_BACKUP_PLAN"
  }
}

resource "aws_config_config_rule" "elb_acm_certificate_required" {
  name = "fedramp-elb-acm-certificate-required"
  source {
    owner             = "AWS"
    source_identifier = "ELB_ACM_CERTIFICATE_REQUIRED"
  }
  scope {
    compliance_resource_types = [
      "AWS::ElasticLoadBalancing::LoadBalancer"
    ]
  }
}

resource "aws_config_config_rule" "emr_kerberos_enabled" {
  name = "fedramp-emr-kerberos-enabled"
  source {
    owner             = "AWS"
    source_identifier = "EMR_KERBEROS_ENABLED"
  }
}

resource "aws_config_config_rule" "internet_gateway_authorized_vpc_only" {
  name = "fedramp-internet-gateway-authorized-vpc-only"
  source {
    owner             = "AWS"
    source_identifier = "INTERNET_GATEWAY_AUTHORIZED_VPC_ONLY"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::InternetGateway"
    ]
  }
}

resource "aws_config_config_rule" "rds_in_backup_plan" {
  name = "fedramp-rds-in-backup-plan"
  source {
    owner             = "AWS"
    source_identifier = "RDS_IN_BACKUP_PLAN"
  }
}

resource "aws_config_config_rule" "s3_account_level_public_access_blocks" {
  name = "fedramp-s3-account-level-public-access-blocks"
  source {
    owner             = "AWS"
    source_identifier = "S3_ACCOUNT_LEVEL_PUBLIC_ACCESS_BLOCKS"
  }
  scope {
    compliance_resource_types = [
      "AWS::S3::AccountPublicAccessBlock"
    ]
  }
  input_parameters = <<EOF
{
    "BlockPublicAcls": "${var.s3_account_level_public_access_blocks_block_public_acls}",
    "BlockPublicPolicy": "${var.s3_account_level_public_access_blocks_block_public_policy}",
    "IgnorePublicAcls": "${var.s3_account_level_public_access_blocks_ignore_public_acls}",
    "RestrictPublicBuckets": "${var.s3_account_level_public_access_blocks_restrict_public_buckets}"
}
EOF
}

resource "aws_config_config_rule" "s3_bucket_policy_grantee_check" {
  name = "fedramp-s3-bucket-policy-grantee-check"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_POLICY_GRANTEE_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::S3::Bucket"
    ]
  }
}


resource "aws_config_config_rule" "secretsmanager_scheduled_rotation_success_check" {
  name = "fedramp-secretsmanager-scheduled-rotation-success-check"
  source {
    owner             = "AWS"
    source_identifier = "SECRETSMANAGER_SCHEDULED_ROTATION_SUCCESS_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::SecretsManager::Secret"
    ]
  }
}
