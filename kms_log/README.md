<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ct-processor-github-alerts"></a> [ct-processor-github-alerts](#module\_ct-processor-github-alerts) | github.com/18F/identity-terraform//lambda_alerts | e0e39adea82243d66c3c1218c7a4316b81f64560 |
| <a name="module_ct-requeue-alerts"></a> [ct-requeue-alerts](#module\_ct-requeue-alerts) | github.com/18F/identity-terraform//lambda_alerts | e0e39adea82243d66c3c1218c7a4316b81f64560 |
| <a name="module_cw-processor-github-alerts"></a> [cw-processor-github-alerts](#module\_cw-processor-github-alerts) | github.com/18F/identity-terraform//lambda_alerts | e0e39adea82243d66c3c1218c7a4316b81f64560 |
| <a name="module_kms_cloudwatch_events_queue_alerts"></a> [kms\_cloudwatch\_events\_queue\_alerts](#module\_kms\_cloudwatch\_events\_queue\_alerts) | github.com/18F/identity-terraform//sqs_alerts | 660048415b30fab9662b1cb32d59672b168be91a |
| <a name="module_kms_ct_queue_alerts"></a> [kms\_ct\_queue\_alerts](#module\_kms\_ct\_queue\_alerts) | github.com/18F/identity-terraform//sqs_alerts | 660048415b30fab9662b1cb32d59672b168be91a |
| <a name="module_reqeue_queue_alerts"></a> [reqeue\_queue\_alerts](#module\_reqeue\_queue\_alerts) | github.com/18F/identity-terraform//sqs_alerts | 660048415b30fab9662b1cb32d59672b168be91a |
| <a name="module_slack-processor-github-alerts"></a> [slack-processor-github-alerts](#module\_slack-processor-github-alerts) | github.com/18F/identity-terraform//lambda_alerts | e0e39adea82243d66c3c1218c7a4316b81f64560 |
| <a name="module_unmatched_queue_alerts"></a> [unmatched\_queue\_alerts](#module\_unmatched\_queue\_alerts) | github.com/18F/identity-terraform//sqs_alerts | 660048415b30fab9662b1cb32d59672b168be91a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.kms_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_event_rule.schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.unmatched](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.cloudtrail_requeue_trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.unmatched_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.unmatched_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_destination.datastream](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination) | resource |
| [aws_cloudwatch_log_destination_policy.subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination_policy) | resource |
| [aws_cloudwatch_log_group.cloudtrail_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.cloudtrail_requeue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.cloudwatch_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.event_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.slack_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.unmatched](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_subscription_filter.kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_cloudwatch_metric_alarm.cloudtrail_lambda_backlog](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.cloudwatch_lambda_backlog](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.dead_letter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_dynamodb_table.kms_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_role.cloudtrail_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cloudtrail_requeue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cloudwatch_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cloudwatch_to_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.event_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.slack_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cloudwatch_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ctprocessor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ctprocessor_dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ctprocessor_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ctrequeue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ctrequeue_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.cwprocessor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.cwprocessor_dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.cwprocessor_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.event_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.event_processor_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.slack_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.slack_processor_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.unmatched_lambda_to_slack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ctprocessor_insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ctrequeue_insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cwprocessor_insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.event_processor_insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.slack_processor_insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kinesis_stream.datastream](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_stream) | resource |
| [aws_kms_alias.kms_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.kms_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lambda_event_source_mapping.cloudtrail_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_event_source_mapping.cloudwatch_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_event_source_mapping.event_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_event_source_mapping.sqs_to_batch_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_function.cloudtrail_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.cloudtrail_requeue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.cloudwatch_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.event_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.slack_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.event_bridge_to_cloudtrail_requeue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sns_topic.kms_logging_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.kms_events_sqs_cw_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.cloudtrail_requeue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.cloudtrail_requeue_dead_letter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.dead_letter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.kms_cloudwatch_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.kms_ct_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.unmatched](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.unmatched_slack_dead_letter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_sqs_queue_policy.events_to_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_sqs_queue_policy.kms_cloudwatch_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_cloudwatch_log_group.kinesis_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudwatch_log_group) | data source |
| [aws_iam_policy.insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.assume_role_kinesis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.assume_role_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudwatch_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ctprocessor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ctrequeue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cwprocessor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.event_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.event_to_sqs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.slack_processor](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sqs_kms_ct_events_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sqs_kms_cw_events_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.unmatched_lambda_to_slack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Environment name | `any` | n/a | yes |
| <a name="input_kinesis_source_log_group"></a> [kinesis\_source\_log\_group](#input\_kinesis\_source\_log\_group) | The source log group the kinesis stream will consume events from | `string` | n/a | yes |
| <a name="input_lambda_kms_ct_processor_zip"></a> [lambda\_kms\_ct\_processor\_zip](#input\_lambda\_kms\_ct\_processor\_zip) | Lambda zip file providing source code for kms cloudtrail processor | `string` | n/a | yes |
| <a name="input_lambda_kms_ct_requeue_zip"></a> [lambda\_kms\_ct\_requeue\_zip](#input\_lambda\_kms\_ct\_requeue\_zip) | Lambda zip file providing source code for kms cloudtrail requeue service | `string` | n/a | yes |
| <a name="input_lambda_kms_cw_processor_zip"></a> [lambda\_kms\_cw\_processor\_zip](#input\_lambda\_kms\_cw\_processor\_zip) | Lambda zip file providing source code for kms cloudwatch processor | `string` | n/a | yes |
| <a name="input_lambda_kms_event_processor_zip"></a> [lambda\_kms\_event\_processor\_zip](#input\_lambda\_kms\_event\_processor\_zip) | Lambda zip file providing source code for kms event processor | `string` | n/a | yes |
| <a name="input_lambda_slack_batch_processor_zip"></a> [lambda\_slack\_batch\_processor\_zip](#input\_lambda\_slack\_batch\_processor\_zip) | Lambda source code that batches KMS events for notification | `string` | n/a | yes |
| <a name="input_sns_topic_dead_letter_arn"></a> [sns\_topic\_dead\_letter\_arn](#input\_sns\_topic\_dead\_letter\_arn) | SNS topic ARN for dead letter queue | `any` | n/a | yes |
| <a name="input_sqs_alarm_actions"></a> [sqs\_alarm\_actions](#input\_sqs\_alarm\_actions) | A list of ARNs to notify when the sqs alarms fire | `list(string)` | n/a | yes |
| <a name="input_sqs_ok_actions"></a> [sqs\_ok\_actions](#input\_sqs\_ok\_actions) | A list of ARNs to notify when the sqs alarms return to an OK state | `list(string)` | n/a | yes |
| <a name="input_alarm_sns_topic_arns"></a> [alarm\_sns\_topic\_arns](#input\_alarm\_sns\_topic\_arns) | List of SNS Topic ARN for alarms | `list(string)` | `[]` | no |
| <a name="input_cloudwatch_filter_pattern"></a> [cloudwatch\_filter\_pattern](#input\_cloudwatch\_filter\_pattern) | Filter pattern for CloudWatch kms.log file | `string` | `"{ ($.kms.action = \"decrypt\" && $.kms.encryption_context.context = %password-digest+|pii-encryption+% ) }"` | no |
| <a name="input_cloudwatch_retention_days"></a> [cloudwatch\_retention\_days](#input\_cloudwatch\_retention\_days) | Number of days to retain CloudWatch Logs for Lambda functions | `number` | `90` | no |
| <a name="input_ct_queue_delay_seconds"></a> [ct\_queue\_delay\_seconds](#input\_ct\_queue\_delay\_seconds) | Number of seconds after the message is placed on the queue before it is able to be received | `number` | `60` | no |
| <a name="input_ct_queue_max_message_size"></a> [ct\_queue\_max\_message\_size](#input\_ct\_queue\_max\_message\_size) | Max message size in bytes | `number` | `4096` | no |
| <a name="input_ct_queue_maxreceivecount"></a> [ct\_queue\_maxreceivecount](#input\_ct\_queue\_maxreceivecount) | Number of times a message will be received before going to the deadletter queue | `number` | `10` | no |
| <a name="input_ct_queue_message_retention_seconds"></a> [ct\_queue\_message\_retention\_seconds](#input\_ct\_queue\_message\_retention\_seconds) | Number of seconds a message will remain in the queue | `number` | `345600` | no |
| <a name="input_ct_queue_visibility_timeout_seconds"></a> [ct\_queue\_visibility\_timeout\_seconds](#input\_ct\_queue\_visibility\_timeout\_seconds) | Number of seconds that a received message is not visible to other workers | `number` | `120` | no |
| <a name="input_ct_requeue_concurrency"></a> [ct\_requeue\_concurrency](#input\_ct\_requeue\_concurrency) | Defines the number of concurrent requeue lambda executions | `number` | `1` | no |
| <a name="input_cw_processor_memory_size"></a> [cw\_processor\_memory\_size](#input\_cw\_processor\_memory\_size) | Defines the amount of memory in MB the CloudWatch Processor can use at runtime | `number` | `128` | no |
| <a name="input_cw_processor_storage_size"></a> [cw\_processor\_storage\_size](#input\_cw\_processor\_storage\_size) | Defines the amount of ephemeral storage (/tmp) in MB available to the CloudWatch Processor | `number` | `512` | no |
| <a name="input_dynamodb_retention_days"></a> [dynamodb\_retention\_days](#input\_dynamodb\_retention\_days) | Number of days to retain kms log records in dynamodb | `number` | `365` | no |
| <a name="input_ec2_kms_arns"></a> [ec2\_kms\_arns](#input\_ec2\_kms\_arns) | ARN(s) of EC2 roles permitted access to KMS | `list` | `[]` | no |
| <a name="input_kinesis_retention_hours"></a> [kinesis\_retention\_hours](#input\_kinesis\_retention\_hours) | Number of hours to retain data in Kinesis data stream.  Max = 168 | `number` | `24` | no |
| <a name="input_kinesis_shard_count"></a> [kinesis\_shard\_count](#input\_kinesis\_shard\_count) | Number of shards to allocate to Kinesis data stream | `number` | `1` | no |
| <a name="input_kmslog_lambda_debug"></a> [kmslog\_lambda\_debug](#input\_kmslog\_lambda\_debug) | Whether to run the kms logging lambdas in debug mode in this account | `bool` | `false` | no |
| <a name="input_kmslog_lambda_dry_run"></a> [kmslog\_lambda\_dry\_run](#input\_kmslog\_lambda\_dry\_run) | Whether to run the kms logging lambdas in dry run mode in this account | `bool` | `false` | no |
| <a name="input_lambda_identity_lambda_functions_gitrev"></a> [lambda\_identity\_lambda\_functions\_gitrev](#input\_lambda\_identity\_lambda\_functions\_gitrev) | Initial gitrev of identity-lambda-functions to deploy (updated outside of terraform) | `string` | `"1815de9b0893548876138e7086391e210cc85813"` | no |
| <a name="input_lambda_insights_account"></a> [lambda\_insights\_account](#input\_lambda\_insights\_account) | The lambda insights account provided by AWS for monitoring | `string` | `"580247275435"` | no |
| <a name="input_lambda_insights_version"></a> [lambda\_insights\_version](#input\_lambda\_insights\_version) | The lambda insights layer version to use for monitoring | `number` | `38` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | `"us-west-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms-cloudwatch-events-queue"></a> [kms-cloudwatch-events-queue](#output\_kms-cloudwatch-events-queue) | Queue for kms logging events to cloudwatch |
| <a name="output_kms-ct-events-queue"></a> [kms-ct-events-queue](#output\_kms-ct-events-queue) | Arn for the kms cloudtrail queue |
| <a name="output_kms-dead-letter-queue"></a> [kms-dead-letter-queue](#output\_kms-dead-letter-queue) | Arn for the kms dead letter queue |
| <a name="output_kms-logging-events-topic"></a> [kms-logging-events-topic](#output\_kms-logging-events-topic) | SNS topic for kms logging events |
| <a name="output_lambda-log-groups"></a> [lambda-log-groups](#output\_lambda-log-groups) | Names of the CloudWatch Log Groups for Lambda functions in this module. |
| <a name="output_unmatched-log-group"></a> [unmatched-log-group](#output\_unmatched-log-group) | Name of the CloudWatch Log Group for unmatched events. |
<!-- END_TF_DOCS -->