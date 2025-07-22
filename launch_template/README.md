# EC2 Launch Template Module

This module is a thin wrapper around creating an EC2 launch template in the
standard Login.gov project format.

https://www.terraform.io/docs/providers/aws/r/launch_template.html

## Usage

Most of the variables are passed through as is to the `launch_template`
resource. The module automatically adds the appropriate `prefix` and `domain`
tags according to the provided instance role and domain.

The `ami_id_map` is a mapping of role name to AMI ID. If the role is not
present in the map, then the `default_ami_id` will be used instead.

```hcl
module "dbserver_launch_template" {
  source = "github.com/18F/identity-terraform//launch_template?ref=main"

  role           = "dbserver"
  env            = "${var.env_name}"
  root_domain    = "${var.root_domain}"
  ami_id_map     = "${var.ami_id_map}"
  default_ami_id = "${local.account_default_ami_id}"

  instance_type             = "c5.large"
  iam_instance_profile_name = "${aws_iam_instance_profile.dbservers.name}"
  security_group_ids        = ["${aws_security_group.dbserver.id}", "${aws_security_group.base.id}"]

  user_data                 = "cloud init user data ..."

  template_tags = {
    tag_for_template = "dbserver v1"
  }

  block_device_mappings = [
    {
      device_name = "/dev/sdg"
      ebs = [
        {
          volume_size = "300"
          volume_type = "gp2"
          encrypted = true
        }
      ]
    }
  ]
}
```

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

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_launch_template.template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_default_tags.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id_map"></a> [ami\_id\_map](#input\_ami\_id\_map) | Mapping from role names to AMI IDs | `map(string)` | n/a | yes |
| <a name="input_default_ami_id"></a> [default\_ami\_id](#input\_default\_ami\_id) | AMI ID to use if the role is not found in the map | `any` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `any` | n/a | yes |
| <a name="input_iam_instance_profile_name"></a> [iam\_instance\_profile\_name](#input\_iam\_instance\_profile\_name) | n/a | `any` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | n/a | `any` | n/a | yes |
| <a name="input_role"></a> [role](#input\_role) | n/a | `any` | n/a | yes |
| <a name="input_root_domain"></a> [root\_domain](#input\_root\_domain) | n/a | `any` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | n/a | `list(string)` | n/a | yes |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | n/a | `any` | n/a | yes |
| <a name="input_block_device_mappings"></a> [block\_device\_mappings](#input\_block\_device\_mappings) | EBS or other block devices to map on created instances. https://www.terraform.io/docs/providers/aws/r/launch_template.html#block-devices | `list(any)` | `[]` | no |
| <a name="input_instance_initiated_shutdown_behavior"></a> [instance\_initiated\_shutdown\_behavior](#input\_instance\_initiated\_shutdown\_behavior) | n/a | `string` | `"terminate"` | no |
| <a name="input_instance_tags"></a> [instance\_tags](#input\_instance\_tags) | Tags to apply to the launched instances | `map(string)` | `{}` | no |
| <a name="input_metadata_response_hop_limit"></a> [metadata\_response\_hop\_limit](#input\_metadata\_response\_hop\_limit) | Desired HTTP PUT response hop limit for instance metadata requests. You might need a larger hop limit for backward compatibility with container services running on the instance. | `number` | `1` | no |
| <a name="input_template_tags"></a> [template\_tags](#input\_template\_tags) | Tags to apply to the launch template | `map(string)` | `{}` | no |
| <a name="input_use_spot_instances"></a> [use\_spot\_instances](#input\_use\_spot\_instances) | Use spot instances - Only suitable if one or more terminated instances are acceptable | `number` | `0` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_latest_version"></a> [latest\_version](#output\_latest\_version) | n/a |
| <a name="output_template_id"></a> [template\_id](#output\_template\_id) | n/a |
| <a name="output_template_name"></a> [template\_name](#output\_template\_name) | n/a |
<!-- END_TF_DOCS -->