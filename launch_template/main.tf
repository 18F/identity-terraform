variable "role" {
}

variable "env" {
  description = "Environment name"
}

variable "root_domain" {
}

variable "ami_id_map" {
  description = "Mapping from role names to AMI IDs"
  type = "map"
}

variable "default_ami_id" {
  description = "AMI ID to use if the role is not found in the map"
}

variable "instance_type" {
}

variable "instance_initiated_shutdown_behavior" {
  default = "terminate"
}

variable "iam_instance_profile_name" {
}

variable "user_data" {
}

variable "security_group_ids" {
  type = "list"
}

variable "template_tags" {
  description = "Tags to apply to the launch template"
  type = "map"
  default = {}
}

variable "block_device_mappings" {
  description = "EBS or other block devices to map on created instances. https://www.terraform.io/docs/providers/aws/r/launch_template.html#block-devices"
  type = "list"
  default = []
}

# ----

resource "aws_launch_template" "template" {
  name = "${var.env}-${var.role}"

  iam_instance_profile {
    name = "${var.iam_instance_profile_name}"
  }

  image_id = "${lookup(var.ami_id_map, var.role, var.default_ami_id)}"

  instance_initiated_shutdown_behavior = "${var.instance_initiated_shutdown_behavior}"

  instance_type = "${var.instance_type}"

  user_data = "${var.user_data}"

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = ["${var.security_group_ids}"]

  tag_specifications {
    resource_type = "instance"
    tags {
      Name = "asg-${var.env}-${var.role}"
      prefix = "${var.role}"
      domain = "${var.env}.${var.root_domain}"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags {
      Name = "asg-${var.env}-${var.role}"
      prefix = "${var.role}"
      domain = "${var.env}.${var.root_domain}"
    }
  }

  tags = "${
    merge(
      map(
        "prefix", "${var.role}",
        "domain", "${var.env}.${var.root_domain}"
      ),
      var.template_tags
    )
  }"

  block_device_mappings = "${var.block_device_mappings}"
}

output "template_id" {
  value = "${aws_launch_template.template.id}"
}
output "template_name" {
  value = "${aws_launch_template.template.name}"
}
