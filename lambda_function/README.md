# lambda_function module

This module provides a consistent framework for creating and monitoring Lambda functions.



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
| <a name="module_lambda_alerts"></a> [lambda\_alerts](#module\_lambda\_alerts) | github.com/18F/identity-terraform//lambda_alerts | b4c39660e888c87e56fb910cca3104bd6a12b093 |
| <a name="module_lambda_code"></a> [lambda\_code](#module\_lambda\_code) | github.com/18F/identity-terraform//null_archive | 6cdd1037f2d1b14315cc8c59b889f4be557b9c17 |
| <a name="module_lambda_insights"></a> [lambda\_insights](#module\_lambda\_insights) | github.com/18F/identity-terraform//lambda_insights | 5c1a8fb0ca08aa5fa01a754a40ceab6c8075d4c9 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_lambda_function.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_actions"></a> [alarm\_actions](#input\_alarm\_actions) | ARNs for Cloudwatch Alarm actions | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Description of the Lambda function | `string` | n/a | yes |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variable for the Lambda function | `map(any)` | n/a | yes |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Name of the Lambda function | `string` | n/a | yes |
| <a name="input_handler"></a> [handler](#input\_handler) | Lambda handler functionn ame | `string` | n/a | yes |
| <a name="input_insights_enabled"></a> [insights\_enabled](#input\_insights\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | How long to retain log files | `number` | n/a | yes |
| <a name="input_log_skip_destroy"></a> [log\_skip\_destroy](#input\_log\_skip\_destroy) | Skip log destruction | `bool` | n/a | yes |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Memory allocated to the Lambda function | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"us-west-2"` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | Lambda function IAM role ARN | `string` | n/a | yes |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Lambda function runtime | `string` | n/a | yes |
| <a name="input_source_code_filename"></a> [source\_code\_filename](#input\_source\_code\_filename) | Name of the file containing the Lambda source code | `string` | n/a | yes |
| <a name="input_source_dir"></a> [source\_dir](#input\_source\_dir) | Directory containing the Lambda source code | `string` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Lambda timeout | `number` | n/a | yes |
| <a name="input_treat_missing_data"></a> [treat\_missing\_data](#input\_treat\_missing\_data) | n/a | `string` | `"nonBreaching"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | n/a |
| <a name="output_lambda_arn"></a> [lambda\_arn](#output\_lambda\_arn) | n/a |
<!-- END_TF_DOCS -->