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
  source = "github.com/18F/identity-terraform//launch_template?ref=master"

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
