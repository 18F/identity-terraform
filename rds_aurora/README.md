# `rds_aurora`

This Terraform module is used to create an AWS Aurora DB cluster, with all configuration options for the cluster available in variable/conditional form. Its primary function is to create a replica cluster pointing to a source RDS database, but can also create a standalone cluster, along with as many instances as desired and any/all associated resources.

## Conditionally-Created Resources

All resources required by the Aurora DB cluster/instances can either ***be created by the module itself***, or ***declared from existing resources***, depending upon which variables are set when declaring an instance of this module.

The following table describes the relationships between module resources and variables, and how they can be individually configured as attributes:

| For this Aurora Cluster / Instance attribute: | This resource will be created:                  | **unless** this variable is set:               |
| :-------------------------------------------- | :---------------------------------------------- | :--------------------------------------------- |
| DB subnets                                    | `aws_subnet.db[*]`                              | `var.db_subnet_ids`                            |
| DB subnet group                               | `aws_db_subnet_group.db`                        | `var.db_subnet_group`<sup>[1](#note-1)</sup>   |
| Security Group                                | `aws_security_group.db`                         | `var.db_security_group`<sup>[2](#note-1)</sup> |
| Route53 record for the reader endpoint        | `aws_route53_record.reader_endpoint`            | `var.internal_zone_id`<sup>[3](#note-1)</sup>  |
| Route53 record for the writer endpoint        | `aws_route53_record.writer_endpoint`            | `var.internal_zone_id`<sup>[3](#note-1)</sup>  |
| KMS key and alias                             | `aws_kms_key.db` / `aws_kms_alias.db`           | `var.db_kms_key_id`                            |
| Enhanced Monitoring IAM role                  | `aws_iam_role.rds_monitoring`                   | `var.monitoring_role`                          |
| EM IAM role policy (attachment)               | `aws_iam_role_policy_attachment.rds_monitoring` | `var.monitoring_role`                          |

***Notes:***

<a style="text-decoration:none;" name="note-1">1.</a> The `aws_db_subnet_group.db` resource CAN be created by the module from existing DB subnets (declared in `var.db_subnet_ids`), even if the `aws_subnet.db[*]` resource(s) are not.
<a style="text-decoration:none;" name="note-2">2.</a> If created, `aws_security_group.db` has a single rule providing ingress on `var.db_port` to any security groups declared in `var.ingress_security_group_ids`.
<a style="text-decoration:none;" name="note-3">3.</a> The Route35 record resources follow the **opposite** behavior -- they will only be created ***if*** `var.internal_zone_id` is declared.

Additionally, once the cluster has been fully created and configured to be a standalone cluster -- thereby allowing individual instances for writing and reading (with as many reader instances as desired) -- Auto Scaling can be added and configured by setting `var.enable_autoscaling` to *true*.

### Creating a Replica Cluster from an Existing RDS Database

This module can be used as a means for migrating from an existing RDS database to a new Aurora DB cluster. If doing so, the `var.rds_db_arn` must be declared with the ARN of the source RDS database (used to configure the `replication_source_identifier` attribute.) Please note:

1. By configuration changes alone, Terraform is ***not*** able to promote a read-replica Aurora DB cluster to a standalone one. As a result, using this module for the process will require a combination of code commits (following GitOps principles) *and* manual API operations for the full process.
2. If `var.rds_db_arn` is not declared -- thus indicating the desire to create a standalone Aurora DB cluster, without an existing database to replicate -- then `var.rds_username` and `var.rds_password` ***must*** be declared instead.
3. If `var.rds_db_arn` *is* declared, the module will set both `var.rds_username` and `var.rds_password` to be empty strings (`""`), as a DB cannot be created with a manually-supplied username/password combination ***and*** a source DB ARN.

## Examples

### 1. Module Creates Standalone DB and All Associated Resources (Minimum Variables Defined)

```terraform
module "db_aurora" {
  source = "github.com/18F/identity-terraform//rds_aurora?ref=main"

  env_name                   = "dev"
  db_identifier              = "primary"
  key_admin_role_name        = "KMSAdministrator"
  rds_password               = var.rds_password # supplied at `apply` step
  rds_username               = var.rds_username # supplied at `apply` step
  apg_cluster_pgroup_params  = local.apg_cluster_pgroup_params
  apg_db_pgroup_params       = local.apg_db_pgroup_params
  db_vpc_id                  = aws_vpc.default.id
  internal_zone_id           = aws_route53_zone.internal.zone_id
  ingress_security_group_ids = [
    aws_security_group.app_host.id,
    aws_security_group.worker_host.id
  ]
}
```

Result:

1. A standalone AuroraDB cluster, `login-dev-primary-us-west-2`, will be created, with all default config values, e.g.:
    - `aurora-postgresql` engine, version 13.5, with `postgresql` CloudWatch log exports
    - Default values for backup retention period, maintenance windows, etc.
    - Ingress provided to DB port `5432` for the supplied `aws_security_group.app_host.id` and `aws_security_group.worker_host.id` Security Groups IDs, which exist within the VPC defined as `aws_vpc.default.id`
    - DB/cluster parameter group configuration defined by supplied `local` variables
2. The database credentials are set with `var.rds_password` and `var.rds_username`
    - An externally-created role, `KMSAdministrator`, is provided permissions to manage the `aws_kms_key.db` / `aws_kms_alias.db` resources
3. All items listed in the Conditionally-Created Resources table will be created, and can be identified in state under `module.db_aurora.<RESOURCE_NAME>`

### 2. Module Creates DB, Configures with Existing Resources, Replicating from an Existing RDS DB Instance (Most/All Variables Defined)

```terraform
module "db_aurora" {
  source = "github.com/18F/identity-terraform//rds_aurora?ref=main"

  name_prefix               = "identity"
  region                    = "us-west-2"
  env_name                  = var.env_name
  db_identifier             = "primary"
  rds_db_arn                = aws_db_instance.primary.arn
  primary_cluster_instances = 1
  key_admin_role_name       = "KMSAdministrator"
  db_instance_class         = var.rds_instance_class_aurora
  db_engine                 = var.rds_engine_aurora
  db_engine_version         = var.rds_engine_version_aurora
  db_port                   = var.rds_db_port
  retention_period          = var.rds_backup_retention_period
  backup_window             = var.rds_backup_window
  maintenance_window        = var.rds_maintenance_window
  auto_minor_upgrades       = false
  major_upgrades            = true
  apg_cluster_pgroup_params = flatten([
    local.apg_cluster_pgroup_params,
    local.apg_param_max_standby_streaming_delay
  ])
  apg_db_pgroup_params = local.apg_db_pgroup_params
  db_subnet_ids        = [for subnet in aws_subnet.persistent_storage : subnet.id]
  db_security_group    = aws_security_group.db.id
  storage_encrypted    = true
  db_kms_key_id        = data.aws_kms_key.rds_alias.arn
  cw_logs_exports      = ["postgresql"]
  pi_enabled           = true
  monitoring_interval  = var.rds_enhanced_monitoring_interval
  monitoring_role      = join(":", [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}",
    "role/${var.rds_monitoring_role_name}"
  ])
  
  internal_zone_id = aws_route53_zone.internal.zone_id
  route53_ttl      = 300
  
  enable_autoscaling    = var.enable_aurora_autoscaling # defaults to false
  # max_cluster_instances = 5      # ignored until enable_autoscaling = true
  
  #### must select ONE pair of variables to use, cannot use both
  #### ignored until enable_autoscaling = true

  # autoscaling_metric_name  = "RDSReaderAverageCPUUtilization"
  # autoscaling_metric_value = 40
  # autoscaling_metric_name  = "RDSReaderAverageDatabaseConnections"
  # autoscaling_metric_value = 1000
}
```

Result:

1. An AuroraDB cluster is created as a replica of the RDS database defined by `aws_db_instance.primary.arn`
2. The `aws_db_subnet_group.db` resource is created, with subnets provided from the `aws_subnet.persistent_storage` resource(s)
3. Parameter group settings are culled from 3 different `local` variables
4. Route53 records for the reader and writer endpoints are created within `aws_route53_zone.internal`
5. NO other resources are created in-module, as all have been separately declared/defined using variables

## Variables

Custom variable values ***must be declared*** if they default to a blank/empty value (e.g. `""`, `[]`) in the table below (unless otherwise specified).

| Category                     | Name                         | Description                                                                                                                                                                                                        | Default                                                                                                  |
| :--------------------------- | :--------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------- |
| Identifiers                  | `region`                     | Primary AWS Region                                                                                                                                                                                                 | `us-west-2`                                                                                              |
| Identifiers                  | `name_prefix`                | Prefix for resource names                                                                                                                                                                                          | `login`                                                                                                  |
| Identifiers                  | `env_name`                   | Environment name                                                                                                                                                                                                   | ""                                                                                                       |
| Identifiers                  | `db_identifier`              | Unique identifier for the database (e.g. `default`/`primary`/etc.)                                                                                                                                                 | ""                                                                                                       |
| Identifiers                  | `rds_db_arn`                 | ARN of RDS DB used as replication source for the Aurora cluster; leave blank if not using an RDS replication source / creating a standalone cluster                                                                | ""                                                                                                       |
| DB Engine / Parameter Config | `db_engine`                  | AuroraDB engine name (`aurora`/`aurora-mysql`/`aurora-postgresql`)                                                                                                                                                 | `aurora-postgresql`                                                                                      |
| DB Engine / Parameter Config | `db_engine_version`          | Version number (e.g. ##.#) of db_engine to use                                                                                                                                                                     | `13.5`                                                                                                   |
| DB Engine / Parameter Config | `db_port`                    | Database port number                                                                                                                                                                                               | **5432**                                                                                                 |
| DB Engine / Parameter Config | `db_instance_class`          | Instance class to use in AuroraDB cluster                                                                                                                                                                          | `db.r5.large`                                                                                            |
| DB Engine / Parameter Config | `apg_cluster_pgroup_params`  | List of parameters to configure for the AuroraDB cluster parameter group                                                                                                                                           | []                                                                                                       |
| DB Engine / Parameter Config | `apg_db_pgroup_params`       | List of parameters to configure for the AuroraDB cluster parameter group                                                                                                                                           | []                                                                                                       |
| Read Replicas / Auto Scaling | `primary_cluster_instances`  | Number of instances to create for the primary AuroraDB cluster; MUST be Set to 1 if creating cluster as a read replica and then should be set to 2+ thereafter                                                     | **2**                                                                                                    |
| Read Replicas / Auto Scaling | `enable_autoscaling`         | Whether or not to enable Auto Scaling of read replica instances                                                                                                                                                    | *false*                                                                                                  |
| Read Replicas / Auto Scaling | `max_cluster_instances`      | Maximum number of read replica instances to scale up to (if enabling Auto Scaling for the Aurora cluster)                                                                                                          | **5**                                                                                                    |
| Read Replicas / Auto Scaling | `autoscaling_metric_name`    | Name of the predefined metric used by the Auto Scaling policy (if enabling Auto Scaling for the Aurora cluster)                                                                                                    | ""                                                                                                       |
| Read Replicas / Auto Scaling | `autoscaling_metric_value`   | Desired target value of Auto Scaling policy's predefined metric (if enabling Auto Scaling for the Aurora cluster)                                                                                                  | **40**                                                                                                   |
| Logging / Monitoring         | `cw_logs_exports`            | List of log types to export to CloudWatch (will use `["general"]` if not specified or `["postgresql"]` if `var.db_engine` is `"aurora-postgresql"`                                                                 | []                                                                                                       |
| Logging / Monitoring         | `pi_enabled`                 | Whether or not to enable Performance Insights on the Aurora cluster                                                                                                                                                | *true*                                                                                                   |
| Logging / Monitoring         | `monitoring_interval`        | Time (in seconds) to wait before each metric sample collection; disabled if set to 0                                                                                                                               | **60**                                                                                                   |
| Logging / Monitoring         | `monitoring_role`            | Name of an existing IAM role with the `AmazonRDSEnhancedMonitoringRole` service role policy attached; will create the `rds_monitoring` IAM role (which has said permission) if this value is left blank            | ""                                                                                                       |
| Maintenance / Upgrades       | `auto_minor_upgrades`        | Whether or not to perform minor engine upgrades automatically during the specified in the maintenance window                                                                                                       | *false*                                                                                                  |
| Maintenance / Upgrades       | `major_upgrades`             | Whether or not to allow performing major version upgrades when changing engine versions                                                                                                                            | *true*                                                                                                   |
| Maintenance / Upgrades       | `retention_period`           | Number of days to retain backups for                                                                                                                                                                               | **34**                                                                                                   |
| Maintenance / Upgrades       | `backup_window`              | Daily time range (in UTC) for automated backups                                                                                                                                                                    | `08:00-08:34`                                                                                            |
| Maintenance / Upgrades       | `maintenance_window`         | Weekly time range (in UTC) for scheduled/system maintenance                                                                                                                                                        | `Sun:08:34-Sun:09:08`                                                                                    |
| Networking                   | `db_security_group`          | VPC Security Group ID used by the AuroraDB cluster; will generate an aws_security_group.db resource and use it instead if left blank. `var.ingress_security_group_ids` CANNOT be empty if this value is left blank | ""                                                                                                       |
| Networking                   | `ingress_security_group_ids` | List of Security Group IDs to be provided ingress from/to `var.db_port` via the `aws_security_group.db` resource; CANNOT be empty if `var.db_security_group` is blank                                              | []                                                                                                       |
| Networking                   | `db_subnet_group`            | Name of private subnet group in the `var.region` VPC; will generate `aws_db_subnet_group.db` resource and use that if left blank                                                                                   | ""                                                                                                       |
| Networking                   | `db_subnet_ids`              | List of private subnet IDs in the `var.region` VPC; will generate `aws_subnet.db*` resources and use those if left empty                                                                                           | []                                                                                                       |
| Networking                   | `az_cidr_map`                | Map of AZs:CIDR ranges for DB subnets; ignored if `var.db_subnet_ids` is set (i.e. imported).                                                                                                                      | <pre style="text-align: left;">{<br>  "a" = "172.16.33.32/28"<br>  "b" = "172.16.33.48/28"<br>  "c" = "172.16.33.64/28"<br>}</pre> |
| Networking                   | `db_vpc_id`                  | ID of the VPC in which to create the `aws_subnet.db*` resources; MUST be set if either `var.db_subnet_ids` or `var.db_security_group` is empty/blank                                                               | ""                                                                                                       |
| Security / KMS               | `storage_encrypted`          | Whether or not to encrypt the underlying Aurora storage layer                                                                                                                                                      | true                                                                                                     |
| Security / KMS               | `db_kms_key_id`              | ID of an already-existing KMS Key used to encrypt the database; will create the `aws_kms_key.db` / `aws_kms_alias.db` resources and use those for encryption if left blank                                         | ""                                                                                                       |
| Security / KMS               | `key_admin_role_name`        | Name of an external IAM role to be granted permissions to interact with the KMS key used for encrypting the database                                                                                               | ""                                                                                                       |
| Security / KMS               | `rds_password`               | Password for the RDS master user account                                                                                                                                                                           | ""                                                                                                       |
| Security / KMS               | `rds_username`               | Username for the RDS master user account                                                                                                                                                                           | ""                                                                                                       |
| Security / KMS               | `skip_final_snapshot`        | Whether or not to skip creating a final snapshot before deleting the Aurora cluster/instance(s)                                                                                                                    | false                                                                                                    |
| Security / KMS               | `deletion_protection`        | Whether or not to enable deletion protection for the cluster                                                                                                                                                       | true                                                                                                     |
| DNS / Route53                | `internal_zone_id`           | ID of the Route53 hosted zone to create records in; leave blank if not configuring DNS/Route53 records for the Aurora cluster/instances                                                                            | ""                                                                                                       |
| DNS / Route53                | `route53_ttl`                | TTL for the Route53 DNS records for the writer/reader endpoints                                                                                                                                                    | **300**                                                                                                  |
