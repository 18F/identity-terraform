resource "aws_config_config_rule" "access_keys_rotated" {
  name = "fedramp-access-keys-rotated"
  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }
  input_parameters = <<EOF
{
    "maxAccessKeyAge": "${var.access_keys_rotated_max_access_key_age}"
}
EOF
}

resource "aws_config_config_rule" "acm_certificate_expiration_check" {
  name = "fedramp-acm-certificate-expiration-check"
  source {
    owner             = "AWS"
    source_identifier = "ACM_CERTIFICATE_EXPIRATION_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::ACM::Certificate"
    ]
  }
  input_parameters = <<EOF
{
    "daysToExpiration": "${var.acm_certificate_expiration_check_days_to_expiration}"
}
EOF
}

resource "aws_config_config_rule" "alb_http_drop_invalid_header_enabled" {
  name = "fedramp-alb-http-drop-invalid-header-enabled"
  source {
    owner             = "AWS"
    source_identifier = "ALB_HTTP_DROP_INVALID_HEADER_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::ElasticLoadBalancingV2::LoadBalancer"
    ]
  }
}

resource "aws_config_config_rule" "alb_http_to_https_redirection_check" {
  name = "fedramp-alb-http-to-https-redirection-check"
  source {
    owner             = "AWS"
    source_identifier = "ALB_HTTP_TO_HTTPS_REDIRECTION_CHECK"
  }
}

resource "aws_config_config_rule" "alb_waf_enabled" {
  name = "fedramp-alb-waf-enabled"
  source {
    owner             = "AWS"
    source_identifier = "ALB_WAF_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::ElasticLoadBalancingV2::LoadBalancer"
    ]
  }
}

resource "aws_config_config_rule" "api_gw_cache_enabled_and_encrypted" {
  name = "fedramp-api-gw-cache-enabled-and-encrypted"
  source {
    owner             = "AWS"
    source_identifier = "API_GW_CACHE_ENABLED_AND_ENCRYPTED"
  }
  scope {
    compliance_resource_types = [
      "AWS::ApiGateway::Stage"
    ]
  }
}

resource "aws_config_config_rule" "api_gw_execution_logging_enabled" {
  name = "fedramp-api-gw-execution-logging-enabled"
  source {
    owner             = "AWS"
    source_identifier = "API_GW_EXECUTION_LOGGING_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::ApiGateway::Stage",
      "AWS::ApiGatewayV2::Stage"
    ]
  }
}

resource "aws_config_config_rule" "autoscaling_group_elb_health_check_required" {
  name = "fedramp-autoscaling_group_elb_health_check_required"
  source {
    owner             = "AWS"
    source_identifier = "AUTOSCALING_GROUP_ELB_HEALTHCHECK_REQUIRED"
  }
  scope {
    compliance_resource_types = [
      "AWS::AutoScaling::AutoScalingGroup"
    ]
  }
}

resource "aws_config_config_rule" "cloudtrail-cloudwatch-logs-enabled" {
  name = "fedramp-cloudtrail-cloudwatch-logs-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_CLOUD_WATCH_LOGS_ENABLED"
  }
}

resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "fedramp-cloudtrail-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
}

resource "aws_config_config_rule" "cloudtrail_encryption_enabled" {
  name = "fedramp-cloudtrail-encryption-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
  }
}

resource "aws_config_config_rule" "cloudtrail_log_file_validation_enabled" {
  name = "fedramp-cloudtrail-log-file-validation-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED"
  }
}

resource "aws_config_config_rule" "cloudtrail_s3_data_events_enabled" {
  name = "fedramp-cloudtrail-s3-data-events-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUDTRAIL_S3_DATAEVENTS_ENABLED"
  }
}

resource "aws_config_config_rule" "cloudtrail_security_trail_enabled" {
  name = "fedramp-cloudtrail-security-trail-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUDTRAIL_SECURITY_TRAIL_ENABLED"
  }
}

resource "aws_config_config_rule" "cloudwatch_alarm_action_check" {
  name = "fedramp-cloudwatch-alarm-action-check"
  source {
    owner             = "AWS"
    source_identifier = "CLOUDWATCH_ALARM_ACTION_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::CloudWatch::Alarm"
    ]
  }
  input_parameters = <<EOF
{
    "alarmActionRequired": "TRUE",
    "insufficientDataActionRequired": "TRUE",
    "okActionRequired": "FALSE"
}
EOF
}

resource "aws_config_config_rule" "cloudwatch_log_group_encrypted" {
  name = "fedramp-cloudwatch-log-group-encrypted"
  source {
    owner             = "AWS"
    source_identifier = "CLOUDWATCH_LOG_GROUP_ENCRYPTED"
  }
}
resource "aws_config_config_rule" "cmk_backing_key_rotation_enabled" {
  name = "fedramp-cmk-backing-key-rotation-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CMK_BACKING_KEY_ROTATION_ENABLED"
  }
}

resource "aws_config_config_rule" "codebuild_project_envvar_awscred_check" {
  name = "fedramp-codebuild-project-envvar-awscred-check"
  source {
    owner             = "AWS"
    source_identifier = "CODEBUILD_PROJECT_ENVVAR_AWSCRED_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::CodeBuild::Project"
    ]
  }
}

resource "aws_config_config_rule" "codebuild_project_source_repo_url_check" {
  name = "fedramp-codebuild-project-source-repo-url-check"
  source {
    owner             = "AWS"
    source_identifier = "CODEBUILD_PROJECT_SOURCE_REPO_URL_CHECK"
  }
}

resource "aws_config_config_rule" "cw_loggroup_retention_period_check" {
  name = "fedramp-cw-loggroup-retention-period-check"
  source {
    owner             = "AWS"
    source_identifier = "CW_LOGGROUP_RETENTION_PERIOD_CHECK"
  }
  input_parameters = <<EOF
{
    "MinRetentionTime": "${var.cw_loggroup_retention_period_check_min_retention_time}"
}
EOF
}

resource "aws_config_config_rule" "db_instance_backup_enabled" {
  name = "fedramp-db-instance-backup-enabled"
  source {
    owner             = "AWS"
    source_identifier = "DB_INSTANCE_BACKUP_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::RDS::DBInstance"
    ]
  }
}

resource "aws_config_config_rule" "dms_replication_not_public" {
  name = "fedramp-dms-replication-not-public"
  source {
    owner             = "AWS"
    source_identifier = "DMS_REPLICATION_NOT_PUBLIC"
  }
}

resource "aws_config_config_rule" "dynamodb_autoscaling_enabled" {
  name = "fedramp-dynamodb-autoscaling-enabled"
  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_AUTOSCALING_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::DynamoDB::Table"
    ]
  }
}

resource "aws_config_config_rule" "dynamodb_in_backup_plan" {
  name = "fedramp-dynamodb-in-backup-plan"
  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_IN_BACKUP_PLAN"
  }
}

resource "aws_config_config_rule" "dynamodb_pitr_enabled" {
  name = "fedramp-dynamodb-pitr-enabled"
  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_PITR_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::DynamoDB::Table"
    ]
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

resource "aws_config_config_rule" "ebs_snapshot_public_restorable_check" {
  name = "fedramp-ebs-snapshot-public-restorable-check"
  source {
    owner             = "AWS"
    source_identifier = "EBS_SNAPSHOT_PUBLIC_RESTORABLE_CHECK"
  }
}

resource "aws_config_config_rule" "ec2_ebs_encryption_by_default" {
  name = "fedramp-ec2-ebs-encryption-by-default"
  source {
    owner             = "AWS"
    source_identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT"
  }
}

resource "aws_config_config_rule" "ec2_imdsv2_check" {
  name = "fedramp-ec2-imdsv2-check"
  source {
    owner             = "AWS"
    source_identifier = "EC2_IMDSV2_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::Instance"
    ]
  }
}

resource "aws_config_config_rule" "ec2_instance_detailed_monitoring_enabled" {
  name = "fedramp-ec2-instance-detailed-monitoring-enabled"
  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_DETAILED_MONITORING_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::Instance"
    ]
  }
}

resource "aws_config_config_rule" "ec2_instance_managed_by_systems_manager" {
  name = "fedramp-ec2-instance-managed-by-systems-manager"
  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_MANAGED_BY_SSM"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::Instance",
      "AWS::SSM::ManagedInstanceInventory"
    ]
  }
}

resource "aws_config_config_rule" "ec2_instance_no_public_ip" {
  name = "fedramp-ec2-instance-no-public-ip"
  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_NO_PUBLIC_IP"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::Instance"
    ]
  }
}

resource "aws_config_config_rule" "ec2_managedinstance_association_compliance_status_check" {
  name = "fedramp-ec2-managedinstance-association-compliance-status-check"
  source {
    owner             = "AWS"
    source_identifier = "AWS::SSM::AssociationCompliance"
  }
  scope {
    compliance_resource_types = [
      "EC2_MANAGEDINSTANCE_ASSOCIATION_COMPLIANCE_STATUS_CHECK"
    ]
  }
}

resource "aws_config_config_rule" "ec2_managedinstance_patch_compliance_status_check" {
  name = "fedramp-c2-managedinstance-patch-compliance-status-check"
  source {
    owner             = "AWS"
    source_identifier = "EC2_MANAGEDINSTANCE_PATCH_COMPLIANCE_STATUS_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::SSM::PatchCompliance"
    ]
  }
}

resource "aws_config_config_rule" "ec2_stopped_instance" {
  name = "fedramp-ec2-stopped-instance"
  source {
    owner             = "AWS"
    source_identifier = "EC2_STOPPED_INSTANCE"
  }
}

resource "aws_config_config_rule" "ec2-volume-inuse-check" {
  name = "fedramp-ec2-volume-inuse-check"
  source {
    owner             = "AWS"
    source_identifier = "EC2_VOLUME_INUSE_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::Volume"
    ]
  }
  input_parameters = <<EOF
{
    "deleteOnTermination": "${var.ec2_volume_inuse_check_delete_on_termination}"
}
EOF
}

resource "aws_config_config_rule" "efs_encrypted_check" {
  name = "fedramp-efs-encrypted-check"
  source {
    owner             = "AWS"
    source_identifier = "EFS_ENCRYPTED_CHECK"
  }
}

resource "aws_config_config_rule" "efs_in_backup_plan" {
  name = "fedramp-efs-in-backup-plan"
  source {
    owner             = "AWS"
    source_identifier = "EFS_IN_BACKUP_PLAN"
  }
}

resource "aws_config_config_rule" "elasticache_redis_cluster_automatic_backup_check" {
  name = "fedramp-elasticache-redis-cluster-automatic-backup-check"
  source {
    owner             = "AWS"
    source_identifier = "ELASTICACHE_REDIS_CLUSTER_AUTOMATIC_BACKUP_CHECK"
  }
}

resource "aws_config_config_rule" "elasticsearch_encrypted_at_rest" {
  name = "fedramp-elasticsearch-encrypted-at-rest"
  source {
    owner             = "AWS"
    source_identifier = "ELASTICSEARCH_ENCRYPTED_AT_REST"
  }
}

resource "aws_config_config_rule" "elasticsearch_in_vpc_only" {
  name = "fedramp-elasticsearch-in-vpc-only"
  source {
    owner             = "AWS"
    source_identifier = "ELASTICSEARCH_IN_VPC_ONLY"
  }
}

resource "aws_config_config_rule" "elasticsearch_node_to_node_encryption_check" {
  name = "fedramp-elasticsearch-node-to-node-encryption-check"
  source {
    owner             = "AWS"
    source_identifier = "ELASTICSEARCH_NODE_TO_NODE_ENCRYPTION_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::Elasticsearch::Domain"
    ]
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

resource "aws_config_config_rule" "elb_cross_zone_load_balancing_enabled" {
  name = "fedramp-elb-cross-zone-load-balancing-enabled"
  source {
    owner             = "AWS"
    source_identifier = "AWS::ElasticLoadBalancing::LoadBalancer"
  }
  scope {
    compliance_resource_types = [
      "ELB_CROSS_ZONE_LOAD_BALANCING_ENABLED"
    ]
  }
}

resource "aws_config_config_rule" "elb_deletion_protection_enabled" {
  name = "fedramp-elb-deletion-protection-enabled"
  source {
    owner             = "AWS"
    source_identifier = "ELB_DELETION_PROTECTION_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::ElasticLoadBalancingV2::LoadBalancer"
    ]
  }
}

resource "aws_config_config_rule" "elb_logging_enabled" {
  name = "fedramp-elb-logging-enabled"
  source {
    owner             = "AWS"
    source_identifier = "ELB_LOGGING_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::ElasticLoadBalancing::LoadBalancer",
      "AWS::ElasticLoadBalancingV2::LoadBalancer"
    ]
  }
}

resource "aws_config_config_rule" "elb_tls_https_listeners_only" {
  name = "fedramp-elb-tls-https-listeners-only"
  source {
    owner             = "AWS"
    source_identifier = "ELB_TLS_HTTPS_LISTENERS_ONLY"
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

resource "aws_config_config_rule" "emr_master_no_public_ip" {
  name = "fedramp-emr-master-no-public-ip"
  source {
    owner             = "AWS"
    source_identifier = "EMR_MASTER_NO_PUBLIC_IP"
  }
}

resource "aws_config_config_rule" "encrypted-volumes" {
  name = "fedramp-encrypted-volumes"
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::Volume"
    ]
  }
}

resource "aws_config_config_rule" "guardduty_enabled_centralized" {
  name = "fedramp-guardduty-enabled-centralized"
  source {
    owner             = "AWS"
    source_identifier = "GUARDDUTY_ENABLED_CENTRALIZED"
  }
}

resource "aws_config_config_rule" "guardduty_non_archived_findings" {
  name = "fedramp-guardduty-non-archived-findings"
  source {
    owner             = "AWS"
    source_identifier = "GUARDDUTY_NON_ARCHIVED_FINDINGS"
  }
  input_parameters = <<EOF
{
    "daysHighSev": "${var.guard_duty_non_archived_findings_days_high_sev}",
    "daysLowSev": "${var.guard_duty_non_archived_findings_days_low_sev}",
    "daysMediumSev": "${var.guard_duty_non_archived_findings_days_medium_sev}"
}
EOF
}

resource "aws_config_config_rule" "iam_group_has_users_check" {
  name = "fedramp-iam-group-has-users-check"
  source {
    owner             = "AWS"
    source_identifier = "IAM_GROUP_HAS_USERS_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::IAM::Group"
    ]
  }
}

resource "aws_config_config_rule" "iam_no_inline_policy_check" {
  name = "fedramp-iam-no-inline-policy-check"
  source {
    owner             = "AWS"
    source_identifier = "IAM_NO_INLINE_POLICY_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::IAM::User",
      "AWS::IAM::Role",
      "AWS::IAM::Group"
    ]
  }
}

resource "aws_config_config_rule" "iam_password_policy" {
  name = "fedramp-iam-password-policy"
  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }
  input_parameters = <<EOF
{
    "MaxPasswordAge": "${var.iam_password_policy_max_password_age}",
    "MinimumPasswordLength": "${var.iam_password_policy_minimum_password_length}",
    "PasswordReusePrevention": "${var.iam_password_policy_password_reuse_prevention}",
    "RequireLowercaseCharacters": "${var.iam_password_policy_require_lowercase_characters}",
    "RequireNumbers": "${var.iam_password_policy_require_numbers}",
    "RequireSymbols": "${var.iam_password_policy_require_symbols}",
    "RequireUppercaseCharacters": "${var.iam_password_policy_require_uppercase_characters}"
}
EOF
}

resource "aws_config_config_rule" "iam_policy_no_statements_with_admin_access" {
  name = "fedramp-iam-policy-no-statements-with-admin-access"
  source {
    owner             = "AWS"
    source_identifier = "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS"
  }
  scope {
    compliance_resource_types = [
      "AWS::IAM::Policy"
    ]
  }
}

resource "aws_config_config_rule" "iam_root_access_key_check" {
  name = "fedramp-iam-root-access-key-check"
  source {
    owner             = "AWS"
    source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
  }
}

resource "aws_config_config_rule" "iam_user_group_membership_check" {
  name = "fedramp-iam-user-group-membership-check"
  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_GROUP_MEMBERSHIP_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::IAM::User"
    ]
  }
}

resource "aws_config_config_rule" "iam_user_mfa_enabled" {
  name = "fedramp-iam-user-mfa-enabled"
  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }
}

resource "aws_config_config_rule" "iam_user_no_policies_check" {
  name = "fedramp-iam-user-no-policies-check"
  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_NO_POLICIES_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::IAM::User"
    ]
  }
}

resource "aws_config_config_rule" "iam_user_unused_credentials_check" {
  name = "fedramp-iam-user-unused-credentials-check"
  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_UNUSED_CREDENTIALS_CHECK"
  }
  input_parameters = <<EOF
{
    "maxCredentialUsageAge": "${var.iam_user_unused_credentials_check_max_credential_usage_age}"
}
EOF
}

resource "aws_config_config_rule" "restricted-ssh" {
  name = "fedramp-restricted-ssh"
  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::SecurityGroup"
    ]
  }
}

resource "aws_config_config_rule" "ec2_instances_in_vpc" {
  name = "fedramp-ec2-instances-in-vpc"
  source {
    owner             = "AWS"
    source_identifier = "INSTANCES_IN_VPC"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::Instance"
    ]
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

resource "aws_config_config_rule" "kms_cmk_not_scheduled_for_deletion" {
  name = "fedramp-kms-cmk-not-scheduled-for-deletion"
  source {
    owner             = "AWS"
    source_identifier = "KMS_CMK_NOT_SCHEDULED_FOR_DELETION"
  }
  scope {
    compliance_resource_types = [
      "AWS::KMS::Key"
    ]
  }
}

resource "aws_config_config_rule" "lambda_function_public_access_prohibited" {
  name = "fedramp-lambda-function-public-access-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED"
  }
  scope {
    compliance_resource_types = [
      "AWS::Lambda::Function"
    ]
  }
}

resource "aws_config_config_rule" "lambda_inside_vpc" {
  name = "fedramp-lambda-inside-vpc"
  source {
    owner             = "AWS"
    source_identifier = "LAMBDA_INSIDE_VPC"
  }
  scope {
    compliance_resource_types = [
      "AWS::Lambda::Function"
    ]
  }
}

resource "aws_config_config_rule" "mfa_enabled_for_iam_console_access" {
  name = "fedramp-mfa-enabled-for-iam-console-access"
  source {
    owner             = "AWS"
    source_identifier = "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS"
  }
}

resource "aws_config_config_rule" "multi_region_cloudtrail_enabled" {
  name = "fedramp-multi-region-cloudtrail-enabled"
  source {
    owner             = "AWS"
    source_identifier = "MULTI_REGION_CLOUD_TRAIL_ENABLED"
  }
}

resource "aws_config_config_rule" "rds_enhanced_monitoring_enabled" {
  name = "fedramp-rds-enhanced-monitoring-enabled"
  source {
    owner             = "AWS"
    source_identifier = "RDS_ENHANCED_MONITORING_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::RDS::DBInstance"
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

resource "aws_config_config_rule" "rds_instance_deletion_protection_enabled" {
  name = "fedramp-rds-instance-deletion-protection-enabled"
  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_DELETION_PROTECTION_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::RDS::DBInstance"
    ]
  }
}

resource "aws_config_config_rule" "rds_instance_public_access_check" {
  name = "fedramp-rds-instance-public-access-check"
  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::RDS::DBInstance"
    ]
  }
}

resource "aws_config_config_rule" "rds_logging_enabled" {
  name = "fedramp-rds-logging-enabled"
  source {
    owner             = "AWS"
    source_identifier = "RDS_LOGGING_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::RDS::DBInstance"
    ]
  }
}

resource "aws_config_config_rule" "rds_multi_az_support" {
  name = "fedramp-rds-multi-az-support"
  source {
    owner             = "AWS"
    source_identifier = "RDS_MULTI_AZ_SUPPORT"
  }
  scope {
    compliance_resource_types = [
      "AWS::RDS::DBInstance"
    ]
  }
}

resource "aws_config_config_rule" "rds_snapshot_encrypted" {
  name = "fedramp-rds-snapshot-encrypted"
  source {
    owner             = "AWS"
    source_identifier = "RDS_SNAPSHOT_ENCRYPTED"
  }
  scope {
    compliance_resource_types = [
      "AWS::RDS::DBSnapshot",
      "AWS::RDS::DBClusterSnapshot"
    ]
  }
}

resource "aws_config_config_rule" "rds_snapshots_public_prohibited" {
  name = "fedramp-ds-snapshots-public-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "RDS_SNAPSHOTS_PUBLIC_PROHIBITED"
  }
  scope {
    compliance_resource_types = [
      "AWS::RDS::DBSnapshot",
      "AWS::RDS::DBClusterSnapshot"
    ]
  }
}

resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "fedramp-rds-storage-encrypted"
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
  scope {
    compliance_resource_types = [
      "AWS::RDS::DBInstance"
    ]
  }
}

resource "aws_config_config_rule" "redshift_cluster_configuration_check" {
  name = "fedramp-redshift-cluster-configuration-check"
  source {
    owner             = "AWS"
    source_identifier = "REDSHIFT_CLUSTER_CONFIGURATION_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::Redshift::Cluster"
    ]
  }
  input_parameters = <<EOF
{
    "clusterDbEncrypted": "TRUE",
    "loggingEnabled": "TRUE"
}
EOF
}

resource "aws_config_config_rule" "redshift_cluster_public_access_check" {
  name = "fedramp-redshift-cluster-public-access-check"
  source {
    owner             = "AWS"
    source_identifier = "REDSHIFT_CLUSTER_PUBLIC_ACCESS_CHECK"
  }
  scope {
    compliance_resource_types = [
      "AWS::Redshift::Cluster"
    ]
  }
}

resource "aws_config_config_rule" "redshift_require_tls_ssl" {
  name = "fedramp-redshift-require-tls-ssl"
  source {
    owner             = "AWS"
    source_identifier = "REDSHIFT_REQUIRE_TLS_SSL"
  }
  scope {
    compliance_resource_types = [
      "AWS::Redshift::Cluster"
    ]
  }
}

resource "aws_config_config_rule" "restricted_common_ports" {
  name = "fedramp-restricted-common-ports"
  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::SecurityGroup"
    ]
  }
  input_parameters = <<EOF
{
    "blockedPort1": "${var.restricted_incoming_traffic_blocked_port1}",
    "blockedPort2": "${var.restricted_incoming_traffic_blocked_port2}",
    "blockedPort3": "${var.restricted_incoming_traffic_blocked_port3}",
    "blockedPort4": "${var.restricted_incoming_traffic_blocked_port4}",
    "blockedPort5": "${var.restricted_incoming_traffic_blocked_port5}"
}
EOF
}

resource "aws_config_config_rule" "root_account_hardware_mfa_enabled" {
  name = "fedramp-root-account-hardware-mfa-enabled"
  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_HARDWARE_MFA_ENABLED"
  }
}

resource "aws_config_config_rule" "root_account_mfa_enabled" {
  name = "fedramp-root-account-mfa-enabled"
  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
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

resource "aws_config_config_rule" "s3_bucket_default_lock_enabled" {
  name = "fedramp-s3-bucket-default-lock-enabled"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_DEFAULT_LOCK_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::S3::Bucket"
    ]
  }
}

resource "aws_config_config_rule" "s3_bucket_logging_enabled" {
  name = "fedramp-s3-bucket-logging-enabled"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LOGGING_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::S3::Bucket"
    ]
  }
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

resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "fedramp-s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  scope {
    compliance_resource_types = [
      "AWS::S3::Bucket"
    ]
  }
}

resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  name = "fedramp-s3-bucket-public-write-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }
  scope {
    compliance_resource_types = [
      "AWS::S3::Bucket"
    ]
  }
}

resource "aws_config_config_rule" "s3_bucket_replication_enabled" {
  name = "fedramp-s3-bucket-replication-enabled"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_REPLICATION_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::S3::Bucket"
    ]
  }
}

resource "aws_config_config_rule" "s3_bucket_server_side_encryption_enabled" {
  name = "fedramp-s3-bucket-server-side-encryption-enabled"
  source {
    owner             = "AWS"
    source_identifier = "AWS::S3::Bucket"
  }
  scope {
    compliance_resource_types = [
      "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
    ]
  }
}

resource "aws_config_config_rule" "s3_bucket_ssl_requests_only" {
  name = "fedramp-s3-bucket-ssl-requests-only"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }
  scope {
    compliance_resource_types = [
      "AWS::S3::Bucket"
    ]
  }
}

resource "aws_config_config_rule" "s3_bucket_versioning_enabled" {
  name = "fedramp-s3-bucket-versioning-enabled"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
  }
  scope {
    compliance_resource_types = [
      "AWS::S3::Bucket"
    ]
  }
}

resource "aws_config_config_rule" "sagemaker_endpoint_configuration_kms_key_configured" {
  name = "fedramp-sagemaker-endpoint-configuration-kms-key-configured"
  source {
    owner             = "AWS"
    source_identifier = "SAGEMAKER_ENDPOINT_CONFIGURATION_KMS_KEY_CONFIGURED"
  }
}

resource "aws_config_config_rule" "sagemaker_notebook_instance_kms_key_configured" {
  name = "fedramp-sagemaker-notebook-instance-kms-key-configured"
  source {
    owner             = "AWS"
    source_identifier = "SAGEMAKER_NOTEBOOK_INSTANCE_KMS_KEY_CONFIGURED"
  }
}

resource "aws_config_config_rule" "sagemaker_notebook_no_direct_internet_access" {
  name = "fedramp-sagemaker-notebook-no-direct-internet-access"
  source {
    owner             = "AWS"
    source_identifier = "SAGEMAKER_NOTEBOOK_NO_DIRECT_INTERNET_ACCESS"
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

resource "aws_config_config_rule" "securityhub_enabled" {
  name = "fedramp-securityhub-enabled"
  source {
    owner             = "AWS"
    source_identifier = "SECURITYHUB_ENABLED"
  }
}

resource "aws_config_config_rule" "sns_encrypted_kms" {
  name = "fedramp-sns-encrypted-kms"
  source {
    owner             = "AWS"
    source_identifier = "SNS_ENCRYPTED_KMS"
  }
  scope {
    compliance_resource_types = [
      "AWS::SNS::Topic"
    ]
  }
}

resource "aws_config_config_rule" "vpc_default_security_group_closed" {
  name = "fedramp-vpc-default-security-group-closed"
  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::SecurityGroup"
    ]
  }
}

resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  name = "fedramp-vpc-flow-logs-enabled"
  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }
}

resource "aws_config_config_rule" "vpc_sg_open_only_to_authorized_ports" {
  name = "fedramp-vpc-sg-open-only-to-authorized-ports"
  source {
    owner             = "AWS"
    source_identifier = "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::SecurityGroup"
    ]
  }
  input_parameters = <<EOF
{
    "authorizedTcpPorts": "${var.vpc_sg_open_only_to_authorized_ports_authorized_tcp_ports}",
    "authorizedUdpPorts": "${var.vpc_sg_open_only_to_authorized_ports_authorized_udp_ports}"
}
EOF
}

resource "aws_config_config_rule" "vpc_vpn_2_tunnels_up" {
  name = "fedramp-vpc-vpn-2-tunnels-up"
  source {
    owner             = "AWS"
    source_identifier = "VPC_VPN_2_TUNNELS_UP"
  }
  scope {
    compliance_resource_types = [
      "AWS::EC2::VPNConnection"
    ]
  }
}

resource "aws_config_config_rule" "wafv2_logging_enabled" {
  name = "fedramp-wafv2-logging-enabled"
  source {
    owner             = "AWS"
    source_identifier = "WAFV2_LOGGING_ENABLED"
  }
}
